defmodule TheronsErp.Purchasing.PurchaseOrder do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Purchasing,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "purchase_orders"
    repo TheronsErp.Repo
  end

  actions do
    create :create do
      accept [:order_date, :delivery_date, :vendor_id, :total_amount]
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
  end
end
