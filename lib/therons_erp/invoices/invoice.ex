defmodule TheronsErp.Invoices.Invoice do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Invoices,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStateMachine],
    authorizers: [Ash.Policy.Authorizer]

  alias TheronsErp.Invoices.LineItem

  postgres do
    table "invoices"
    repo TheronsErp.Repo
  end

  state_machine do
    initial_states([:draft])
    default_initial_state(:draft)

    transitions do
      transition(:send, from: [:draft], to: [:sent])
    end
  end

  actions do
    defaults [
      :read,
      update: [:customer_id, :sales_order_id, :paid_amount]
    ]

    update :send do
      change transition_state(:sent)
    end

    update :pay do
      accept [:paid_amount]
      change transition_state(:paid)
    end

    destroy :destroy do
      primary? true
      change cascade_destroy(:line_items, action: :destroy)
    end

    create :create do
      accept [:customer_id, :sales_order_id]
      argument :sales_lines, {:array, :map}

      change fn changeset, context ->
        changeset
        |> Ash.Changeset.after_action(fn changeset, result ->
          sales_lines = Ash.Changeset.get_argument(changeset, :sales_lines)

          for line <- sales_lines do
            LineItem.create(%{
              price: line.sales_price,
              quantity: line.quantity,
              invoice_id: result.id,
              product_id: line.product_id
            })
          end

          {:ok, result}
        end)
        |> then(fn changeset ->
          sales_order =
            Ash.get!(
              TheronsErp.Sales.SalesOrder,
              Ash.Changeset.get_attribute(changeset, :sales_order_id),
              load: [:total_price]
            )

          Ash.Changeset.change_attribute(changeset, :paid_amount, sales_order.total_price)
        end)
      end
    end
  end

  policies do
    policy action(:destroy) do
      authorize_if expr(state == "draft")
    end

    policy action_type(:create) do
      authorize_if always()
    end

    policy action_type(:update) do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if always()
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :identifier, :integer do
      generated? true
    end

    attribute :paid_amount, :money

    timestamps()
  end

  relationships do
    belongs_to :customer, TheronsErp.People.Entity do
      allow_nil? false
    end

    belongs_to :sales_order, TheronsErp.Sales.SalesOrder
    has_many :line_items, TheronsErp.Invoices.LineItem
  end

  aggregates do
    sum :total_price, [:line_items], :total_price
  end
end
