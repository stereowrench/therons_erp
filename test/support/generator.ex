defmodule TheronsErp.Generator do
  use Ash.Generator

  def product(opts \\ []) do
    seed_generator(
      %TheronsErp.Inventory.Product{
        name: Faker.Commerce.En.product_name(),
        identifier: Faker.random_between(1, 10_000_000_000),
        sales_price: Money.new(500, :USD),
        type: :goods
      },
      overrides: opts
    )
  end

  def product_category(opts \\ []) do
    changeset_generator(
      TheronsErp.Inventory.ProductCategory,
      :create,
      defaults: %{
        name: Faker.Commerce.En.product_name(),
        product_category_id: nil
      },
      overrides: opts
    )
  end
end
