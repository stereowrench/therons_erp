defmodule TheronsErp.Factory do
  use ExMachina.Ecto, repo: TheronsErp.Repo

  def product_factory() do
    %TheronsErp.Inventory.Product{
      id: Faker.UUID.v4(),
      name: Faker.Commerce.En.product_name(),
      identifier: Faker.random_between(1, 10_000_000_000),
      sales_price: Money.new(500, :USD),
      type: TheronsErp.Inventory.Product.Types.values() |> Enum.random(),
      inserted_at: Faker.DateTime.backward(7),
      updated_at: Faker.DateTime.backward(7)
    }
    |> AshPostgres.DataLayer.to_ecto()
  end

  def product_category_factory() do
    %TheronsErp.Inventory.ProductCategory{
      id: Faker.UUID.v4(),
      name: Faker.Commerce.En.product_name(),
      product_category_id: Faker.UUID.v4(),
      full_name: Faker.Commerce.En.product_name(),
      inserted_at: Faker.DateTime.backward(7),
      updated_at: Faker.DateTime.backward(7)
    }
  end
end
