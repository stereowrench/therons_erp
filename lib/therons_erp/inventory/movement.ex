defmodule TheronsErp.Inventory.Movement do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Inventory,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStateMachine]

  postgres do
    table "movements"
    repo TheronsErp.Repo
  end

  state_machine do
    initial_states([:ready])
    default_initial_state(:ready)

    transitions do
      transition(:move, from: [:ready], to: [:moved])
      transition(:actualize, from: [:ready], to: [:moved])
    end
  end

  code_interface do
    define :actualize
  end

  actions do
    read :read do
      primary? true
    end

    update :move do
      change transition_state(:moved)
    end

    create :create do
      accept [
        :from_location_id,
        :to_location_id,
        :quantity,
        :manually_created,
        :product_id,
        :actual_transfer_id,
        :predicted_transfer_id,
        :eager_transfer_id
      ]

      change fn changeset, _ ->
        get_locations(changeset, :actual)
        get_locations(changeset, :predicted)
        get_locations(changeset, :eager)
        changeset
      end

      change &create_predicted/2
    end

    update :update do
      accept [
        :from_location_id,
        :to_location_id,
        :quantity,
        :manually_created,
        :product_id,
        :actual_transfer_id,
        :predicted_transfer_id,
        :eager_transfer_id
      ]
    end

    destroy :destroy do
    end

    update :actualize do
      require_atomic? false
      change transition_state(:moved)

      change fn changeset, _ ->
        amount = Ash.Changeset.get_attribute(changeset, :quantity)
        {from_account_id, to_account_id} = get_locations(changeset, :actual)

        {:ok, actual_transfer} =
          TheronsErp.Ledger.Transfer
          |> Ash.Changeset.for_create(
            :transfer,
            %{
              from_account_id: from_account_id,
              to_account_id: to_account_id,
              amount: Money.new(amount, :XIT)
            }
          )
          |> Ash.create()

        changeset
        |> Ash.Changeset.change_attribute(:actual_transfer_id, actual_transfer.id)
      end
    end
  end

  defp get_locations(changeset, type) do
    product_id = Ash.Changeset.get_attribute(changeset, :product_id)
    product = Ash.get!(TheronsErp.Inventory.Product, product_id)

    from_location_id = Ash.Changeset.get_attribute(changeset, :from_location_id)

    from_account_id =
      get_acct_id(get_inv_identifier(type, from_location_id, product.identifier))

    to_location_id = Ash.Changeset.get_attribute(changeset, :to_location_id)

    to_account_id =
      get_acct_id(get_inv_identifier(type, to_location_id, product.identifier))

    {from_account_id, to_account_id}
  end

  def create_predicted(changeset, _context) do
    amount = Ash.Changeset.get_attribute(changeset, :quantity)

    {from_account_id, to_account_id} = get_locations(changeset, :predicted)

    date = Ash.Changeset.get_attribute(changeset, :date)

    {:ok, predicted_transfer} =
      TheronsErp.Ledger.Transfer
      |> Ash.Changeset.for_create(
        :transfer,
        %{
          from_account_id: from_account_id,
          to_account_id: to_account_id,
          amount: Money.new(amount, :XIT),
          timestamp: date || MyDate.today()
        }
      )
      |> Ash.create()

    changeset
    |> Ash.Changeset.change_attribute(:predicted_transfer_id, predicted_transfer.id)
  end

  attributes do
    uuid_primary_key :id

    attribute :quantity, :decimal

    attribute :manually_created, :boolean, default: false

    attribute :date, :date

    timestamps()
  end

  relationships do
    belongs_to :product, TheronsErp.Inventory.Product do
      allow_nil? false
    end

    belongs_to :actual_transfer, TheronsErp.Ledger.Transfer, attribute_type: AshDoubleEntry.ULID

    belongs_to :predicted_transfer, TheronsErp.Ledger.Transfer,
      attribute_type: AshDoubleEntry.ULID

    belongs_to :eager_transfer, TheronsErp.Ledger.Transfer, attribute_type: AshDoubleEntry.ULID

    belongs_to :from_location, TheronsErp.Inventory.Location do
      allow_nil? false
    end

    belongs_to :to_location, TheronsErp.Inventory.Location do
      allow_nil? false
    end
  end

  def get_acct_id(identifier) do
    TheronsErp.Ledger.Account
    |> Ash.get(%{identifier: identifier})
    |> case do
      {:error, _} ->
        # create acct
        TheronsErp.Ledger.Account
        |> Ash.Changeset.for_create(:open, %{
          identifier: identifier,
          currency: "XIT"
        })
        |> Ash.create!()
        |> then(& &1.id)

      {:ok, el} ->
        el.id
    end
  end

  def get_inv_identifier(:actual, location_id, product_identifier) do
    "inv.actual.#{location_id}.#{product_identifier}"
  end

  def get_inv_identifier(:predicted, location_id, product_identifier) do
    "inv.predicted.#{location_id}.#{product_identifier}"
  end

  def get_inv_identifier(:eager, location_id, product_identifier) do
    "inv.eager.#{location_id}.#{product_identifier}"
  end

  def get_po_identifier(po, po_item) do
    "po.#{po.id}.#{po_item.id}"
  end
end
