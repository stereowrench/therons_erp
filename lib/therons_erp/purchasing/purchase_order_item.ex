defmodule TheronsErp.Purchasing.PurchaseOrderItem do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Purchasing,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStateMachine]

  postgres do
    table "purchase_order_items"
    repo TheronsErp.Repo
  end

  state_machine do
    initial_states([:draft])
    default_initial_state(:draft)

    transitions do
      # transition(:)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :quantity, :decimal
    attribute :unit_price, :money
  end

  relationships do
    belongs_to :purchase_order, TheronsErp.Purchasing.PurchaseOrder
    belongs_to :product, TheronsErp.Inventory.Product
  end
end
