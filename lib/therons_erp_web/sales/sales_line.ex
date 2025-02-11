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
      accept [:sales_price, :unit_price, :quantity, :product_id]
    end

    update :update do
      require_atomic? false
      primary? true
      accept [:sales_price, :unit_price, :quantity, :product_id]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :sales_price, :money
    attribute :unit_price, :money
    attribute :quantity, :integer

    attribute :total_price, :money

    timestamps()
  end

  relationships do
    belongs_to :sales_order, TheronsErp.Sales.SalesOrder do
      allow_nil? false
    end

    belongs_to :product, TheronsErp.Inventory.Product do
      allow_nil? false
    end
  end

  calculations do
    calculate :calculated_total_price, :money, expr(sales_price * quantity)

    calculate :active_price, :money, expr(total_price || calculated_total_price)

    calculate :total_cost, :money, expr(unit_price * quantity)
    # calculate :margin do
    # end
  end
end
