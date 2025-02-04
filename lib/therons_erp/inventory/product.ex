defmodule TheronsErp.Inventory.Product do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Inventory

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    attribute :sales_price, :money
    attribute :type, TheronsErp.Inventory.Product.Types
    timestamps()
  end

  relationships do
    belongs_to :category, TheronsErp.Inventory.ProductCategory
  end
end
