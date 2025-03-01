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
      accept [:sales_price, :unit_price, :quantity, :product_id, :sales_order_id]

      # Set unit_price and sales_price based on product price and cost
      change fn changeset, _ ->
        # Load the product if it exists
        if product_id = Ash.Changeset.get_attribute(changeset, :product_id) do
          product = Ash.get!(TheronsErp.Inventory.Product, product_id)

          changeset
          |> Ash.Changeset.change_attribute(:unit_price, product.cost)
          |> Ash.Changeset.change_attribute(:sales_price, product.sales_price)
        else
          changeset
        end
      end
    end

    update :update do
      require_atomic? false
      primary? true
      accept [:sales_price, :unit_price, :quantity, :product_id, :total_price, :sales_order_id]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :sales_price, :money
    attribute :unit_price, :money

    attribute :quantity, :integer do
      default 1
    end

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

    calculate :product_cost, :money, expr(product.cost)
    calculate :product_price, :money, expr(product.price)

    # calculate :margin do
    # end
  end
end
