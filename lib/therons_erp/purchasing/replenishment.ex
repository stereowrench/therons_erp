defmodule TheronsErp.Purchasing.Replenishment do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Purchasing,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "replenishments"
    repo TheronsErp.Repo
  end

  actions do
    read :read do
    end

    create :create do
      accept [:product_id, :vendor_id, :trigger_quantity, :quantity_multiple, :price]
    end

    update :update do
      accept [:product_id, :vendor_id, :trigger_quantity, :quantity_multiple, :price]
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :quantity_multiple, :integer
    attribute :price, :money

    attribute :trigger_quantity, :integer

    timestamps()
  end

  relationships do
    belongs_to :product, TheronsErp.Inventory.Product

    belongs_to :vendor, TheronsErp.Purchasing.Vendor
  end
end
