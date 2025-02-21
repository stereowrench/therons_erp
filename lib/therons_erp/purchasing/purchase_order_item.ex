defmodule TheronsErp.Purchasing.PurchaseOrderItem do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Purchasing,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "purchase_order_items"
    repo TheronsErp.Repo
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
