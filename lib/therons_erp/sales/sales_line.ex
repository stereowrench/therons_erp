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

      accept [
        :sales_price,
        :unit_price,
        :quantity,
        :product_id,
        :sales_order_id,
        :pull_location_id
      ]

      # Set unit_price and sales_price based on product price and cost
      change fn changeset, _ ->
        # Load the product if it exists
        if Ash.Changeset.get_attribute(changeset, :product_id) &&
             (!Ash.Changeset.get_attribute(changeset, :sales_price) ||
                !Ash.Changeset.get_attribute(changeset, :unit_price) ||
                !Ash.Changeset.get_attribute(changeset, :quantity)) do
          product_id = Ash.Changeset.get_attribute(changeset, :product_id)
          product = Ash.get!(TheronsErp.Inventory.Product, product_id)

          changeset
          |> Ash.Changeset.change_attribute(:unit_price, product.cost)
          |> Ash.Changeset.change_attribute(:sales_price, product.sales_price)
        else
          changeset
        end
      end

      change &add_pull_location/2
    end

    update :update do
      require_atomic? false
      primary? true

      accept [
        :sales_price,
        :unit_price,
        :quantity,
        :product_id,
        :total_price,
        :sales_order_id,
        :pull_location_id
      ]

      change &add_pull_location/2
    end
  end

  def add_pull_location(changeset, result) do
    if Ash.Changeset.get_attribute(changeset, :pull_location_id) == nil do
      loc =
        TheronsErp.Inventory.Location
        |> Ash.Changeset.for_create(:create, %{name: "warehouse.storage"})
        |> Ash.create!()

      Ash.Changeset.change_attribute(changeset, :pull_location_id, loc.id)
    else
      changeset
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

    belongs_to :pull_location, TheronsErp.Inventory.Location
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
