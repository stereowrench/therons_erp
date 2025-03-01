defmodule TheronsErp.Inventory.ProductRoutes do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Inventory,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "product_routes"
    repo TheronsErp.Repo
  end

  actions do
    read :read do
      primary? true
    end

    create :create do
      accept [:product_id, :routes_id]
      primary? true
    end

    destroy :destroy do
      primary? true
    end
  end

  relationships do
    belongs_to :product, TheronsErp.Inventory.Product, primary_key?: true, allow_nil?: false
    belongs_to :routes, TheronsErp.Inventory.Routes, primary_key?: true, allow_nil?: false
  end
end
