defmodule TheronsErp.Purchasing.Replenishment do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Purchasing,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "replenishments"
    repo TheronsErp.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :quantity_multiple, :integer
    attribute :price, :money
    timestamps()
  end

  relationships do
    belongs_to :product, TheronsErp.Inventory.Product

    belongs_to :vendor, TheronsErp.Purchasing.Vendor
  end
end
