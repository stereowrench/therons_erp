defmodule TheronsErp.Sales.SalesOrder do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Sales,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStateMachine],
    primary_read_warning?: false

  alias TheronsErp.Invoices.Invoice

  postgres do
    table "sales_orders"
    repo TheronsErp.Repo
  end

  state_machine do
    initial_states([:draft])
    default_initial_state(:draft)

    transitions do
      transition(:ready, from: :draft, to: [:ready, :cancelled])
      transition(:invoice, from: :ready, to: [:invoiced])
      transition(:cancel, from: [:draft, :ready], to: :cancelled)
      transition(:cancel_invoice, from: [:invoiced], to: :cancelled)
      transition(:revive, from: [:cancelled, :ready], to: [:draft, :ready])
      transition(:complete, from: [:draft, :ready, :invoiced], to: :complete)
    end
  end

  actions do
    update :invoice do
      require_atomic? false
      change transition_state(:invoiced)

      change fn changeset, result ->
        Ash.Changeset.after_action(changeset, fn changeset, result ->
          Invoice
          |> Ash.Changeset.for_create(:create, %{
            sales_order_id: result.id,
            sales_lines: result.sales_lines,
            customer_id: result.customer_id
          })
          |> Ash.create!()

          {:ok, result}
        end)
      end
    end

    update :cancel_invoice do
      change transition_state(:cancelled)

      change fn changeset, result ->
        Ash.changeset().after_action(changeset, fn changeset, result ->
          invoice =
            Ash.get!(
              TheronsErp.Invoices.Invoice,
              Ash.Changeset.get_attribute(changeset, :invoice_id)
            )

          Ash.destroy!(invoice)

          {:ok, result}
        end)
      end
    end

    update :ready do
      change transition_state(:ready)
    end

    update :cancel do
      change transition_state(:cancelled)
    end

    update :revive do
      change transition_state(:draft)
    end

    update :complete do
      change transition_state(:complete)
    end

    read :read do
      primary? true
      prepare build(sort: [identifier: :desc])
    end

    destroy :destroy do
    end

    create :create do
      accept [:customer_id, :address_id]
      primary? true
      argument :sales_lines, {:array, :map}

      change manage_relationship(:sales_lines, type: :create),
        where: [attribute_equals(:state, :draft)]

      # TODO validate address belongs to customer
    end

    update :update do
      accept [:customer_id, :address_id]
      require_atomic? false
      argument :sales_lines, {:array, :map}

      validate present(:customer_id)
      validate present(:address_id)

      change manage_relationship(:sales_lines, type: :direct_control),
        where: [attribute_equals(:state, :draft)]

      # TODO validate address belongs to customer
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :identifier, :integer do
      generated? true
    end

    timestamps()
  end

  relationships do
    has_many :sales_lines, TheronsErp.Sales.SalesLine do
      destination_attribute :sales_order_id
      sort id: :desc
    end

    belongs_to :customer, TheronsErp.People.Entity

    belongs_to :address, TheronsErp.People.Address

    has_one :invoice, TheronsErp.Invoices.Invoice do
      destination_attribute :sales_order_id
    end
  end

  aggregates do
    sum :total_price, [:sales_lines], :active_price
    sum :total_cost, [:sales_lines], :total_cost
  end
end
