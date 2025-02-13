defmodule TheronsErp.Sales.SalesOrder do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Sales,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStateMachine]

  postgres do
    table "sales_orders"
    repo TheronsErp.Repo
  end

  state_machine do
    initial_states([:draft])
    default_initial_state(:draft)

    transitions do
      transition(:ready, from: :draft, to: [:ready, :cancelled])
      transition(:cancel, from: [:draft, :ready], to: :cancelled)
      transition(:revive, from: [:cancelled, :ready], to: [:draft, :ready])
      transition(:complete, from: [:draft, :ready], to: :complete)
    end
  end

  actions do
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
  end

  aggregates do
    sum :total_price, [:sales_lines], :active_price
    sum :total_cost, [:sales_lines], :total_cost
  end
end
