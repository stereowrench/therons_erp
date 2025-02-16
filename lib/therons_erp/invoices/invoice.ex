defmodule TheronsErp.Invoices.Invoice do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Invoices,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStateMachine]

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
      update: [:customer_id, :sales_order_id]
    ]

    update :send do
      change transition_state(:sent)
    end

    create :create do
      accept [:customer_id, :sales_order_id]
      argument :sales_lines, {:array, :map}

      change fn changeset, context ->
        IO.inspect(changeset)
        changeset
      end
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
    belongs_to :customer, TheronsErp.People.Entity
    belongs_to :sales_order, TheronsErp.Sales.SalesOrder
    has_many :line_items, TheronsErp.Invoices.LineItem
  end
end
