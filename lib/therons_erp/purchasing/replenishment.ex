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
      primary? true
    end

    create :create do
      accept [
        :product_id,
        :vendor_id,
        :trigger_quantity,
        :quantity_multiple,
        :price,
        :lead_time_days
      ]
    end

    update :update do
      accept [
        :product_id,
        :vendor_id,
        :trigger_quantity,
        :quantity_multiple,
        :price,
        :lead_time_days
      ]
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :quantity_multiple, :integer
    attribute :price, :money

    attribute :trigger_quantity, :decimal

    attribute :lead_time_days, :integer do
      default 1
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :product, TheronsErp.Inventory.Product do
      allow_nil? false
    end

    belongs_to :vendor, TheronsErp.Purchasing.Vendor do
      allow_nil? false
    end
  end
end
