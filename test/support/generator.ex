defmodule TheronsErp.Generator do
  use Ash.Generator

  def product(opts \\ []) do
    seed_generator(
      %TheronsErp.Inventory.Product{
        id: Faker.UUID.v4(),
        name: Faker.Commerce.En.product_name(),
        identifier: Faker.random_between(1, 10_000_000_000),
        sales_price: Money.new(500, :USD),
        type: TheronsErp.Inventory.Product.Types.values() |> Enum.random(),
        inserted_at: Faker.DateTime.backward(7),
        updated_at: Faker.DateTime.backward(7)
      },
      overrides: opts
    )
  end

  def product_category(opts \\ []) do
    seed_generator(
      %TheronsErp.Inventory.ProductCategory{
        id: Faker.UUID.v4(),
        name: Faker.Commerce.En.product_name(),
        product_category_id: Faker.UUID.v4(),
        full_name: Faker.Commerce.En.product_name(),
        inserted_at: Faker.DateTime.backward(7),
        updated_at: Faker.DateTime.backward(7)
      },
      overrides: opts
    )
  end
end
