defmodule TheronsErp.Inventory.ProductCategory do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Inventory,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "product_categories"
    repo TheronsErp.Repo
  end

  actions do
    defaults [:read]

    create :create do
      accept [:name, :product_category_id]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    attribute :product_category_id, :uuid

    timestamps()
  end

  relationships do
    belongs_to :product_category, TheronsErp.Inventory.ProductCategory

    has_many :subcategories, TheronsErp.Inventory.ProductCategory do
      destination_attribute :product_category_id
    end
  end
end
