defmodule TheronsErp.Inventory.Routes do
  use Ash.Resource,
    otp_app: :therons_erp,
    data_layer: AshPostgres.DataLayer,
    domain: TheronsErp.Inventory

  postgres do
    table "routes"
    repo TheronsErp.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :fallback, :atom, constraints: [one_of: [:mto, :mtso]]

    attribute :routes, {:array, TheronsErp.Inventory.Route}

    timestamps()
  end

  relationships do
    has_many :products, TheronsErp.Inventory.Product do
      destination_attribute :route_id
    end
  end
end
