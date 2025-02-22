defmodule TheronsErp.Inventory.Product do
  use Ash.Resource,
    otp_app: :therons_erp,
    data_layer: AshPostgres.DataLayer,
    domain: TheronsErp.Inventory,
    primary_read_warning?: false

  postgres do
    table "products"
    repo TheronsErp.Repo
  end

  actions do
    defaults [:read]

    read :list do
      primary? true
      prepare build(sort: [identifier: :desc])
    end

    read :list_saleable do
      filter expr(saleable == true)
      prepare build(sort: [identifier: :desc])
    end

    create :create do
      accept [:name, :sales_price, :type, :category_id, :saleable, :purchaseable, :cost]
    end

    create :create_stub do
      accept []

      change fn changeset, context ->
        Ash.Changeset.change_attribute(changeset, :name, "New Product")
      end
    end

    update :update do
      accept [:name, :sales_price, :type, :category_id, :saleable, :purchaseable, :cost]
    end

    destroy :destroy do
      primary? true
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    attribute :identifier, :integer do
      generated? true
    end

    attribute :sales_price, :money
    attribute :cost, :money

    attribute :type, TheronsErp.Inventory.Product.Types do
      default :goods
    end

    attribute :saleable, :boolean do
      default true
    end

    attribute :purchaseable, :boolean do
      default false
    end

    timestamps()
  end

  relationships do
    belongs_to :category, TheronsErp.Inventory.ProductCategory

    belongs_to :route, TheronsErp.Inventory.Routes
  end
end
