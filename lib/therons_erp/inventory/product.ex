defmodule TheronsErp.Inventory.Product do
  use Ash.Resource,
    otp_app: :therons_erp,
    data_layer: AshPostgres.DataLayer,
    domain: TheronsErp.Inventory

  postgres do
    table "products"
    repo TheronsErp.Repo
  end

  actions do
    defaults [:read]

    create :create do
      accept [:name, :sales_price, :type, :category_id]
    end

    update :update do
      accept [:name, :sales_price, :type, :category_id]
    end

    destroy :destroy do
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    attribute :sales_price, :money

    attribute :type, TheronsErp.Inventory.Product.Types do
      default :goods
    end

    timestamps()
  end

  relationships do
    belongs_to :category, TheronsErp.Inventory.ProductCategory
  end
end
