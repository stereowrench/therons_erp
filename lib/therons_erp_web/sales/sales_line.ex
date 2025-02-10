defmodule TheronsErp.Sales.SalesLine do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Sales,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "sales_lines"
    repo TheronsErp.Repo
  end

  actions do
    defaults [:destroy, :read]

    create :create do
      primary? true
      accept [:sales_price, :unit_price, :quantity]
    end

    update :update do
      primary? true
      accept [:sales_price, :unit_price, :quantity]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :sales_price, :money
    attribute :unit_price, :money
    attribute :quantity, :integer
    timestamps()
  end

  relationships do
    belongs_to :sales_order, TheronsErp.Sales.SalesOrder
    belongs_to :product, TheronsErp.Inventory.Product
  end
end
