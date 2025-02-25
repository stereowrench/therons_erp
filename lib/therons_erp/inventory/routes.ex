defmodule TheronsErp.Inventory.Routes do
  use Ash.Resource,
    otp_app: :therons_erp,
    data_layer: AshPostgres.DataLayer,
    domain: TheronsErp.Inventory

  postgres do
    table "routes"
    repo TheronsErp.Repo
  end

  actions do
    read :list do
      primary? true
    end

    create :create do
      accept [:name, :fallback, :routes, :type]
    end

    update :update do
      accept [:name, :fallback, :routes, :type]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    attribute :fallback, :atom, constraints: [one_of: [:mto, :mtso]]

    attribute :routes, {:array, TheronsErp.Inventory.Route}

    attribute :type, :atom do
      constraints one_of: [:push, :pull]
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    many_to_many :products, TheronsErp.Inventory.Product do
      through TheronsErp.Inventory.ProductRoutes
      source_attribute :id
      source_attribute_on_join_resource :routes_id

      destination_attribute :id
      destination_attribute_on_join_resource :product_id
    end
  end
end
