defmodule TheronsErp.Purchasing.PurchaseOrder do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Purchasing,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "purchase_orders"
    repo TheronsErp.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :order_date, :date
    attribute :delivery_date, :date
    attribute :total_amount, :money
    timestamps()
  end

  relationships do
    belongs_to :vendor, TheronsErp.Purchasing.Vendor

    has_many :items, TheronsErp.Purchasing.PurchaseOrderItem
  end
end
