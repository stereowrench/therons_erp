defmodule TheronsErp.Purchasing.PurchaseOrder do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Purchasing,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStateMachine]

  postgres do
    table "purchase_orders"
    repo TheronsErp.Repo
  end

  state_machine do
    initial_states([:created])
    default_initial_state(:created)

    transitions do
      transition(:receive, from: :created, to: [:received])
    end
  end

  actions do
    read :read do
      primary? true
    end

    create :create do
      accept [:order_date, :delivery_date, :vendor_id, :total_amount, :destination_location_id]
    end

    update :receive do
      accept [:delivery_date, :total_amount]
      change transition_state(:received)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :order_date, :date
    attribute :delivery_date, :date
    attribute :total_amount, :money

    attribute :identifier, :integer do
      generated? true
    end

    timestamps()
  end

  relationships do
    belongs_to :vendor, TheronsErp.Purchasing.Vendor

    has_many :items, TheronsErp.Purchasing.PurchaseOrderItem

    belongs_to :destination_location, TheronsErp.Inventory.Location do
      allow_nil? false
    end
  end
end
