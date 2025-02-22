defmodule TheronsErp.Generator do
  use Ash.Generator

  def routes(opts \\ []) do
    seed_generator(
      %TheronsErp.Inventory.Routes{
        name: Faker.Commerce.En.product_name()
      },
      overrides: opts
    )
  end

  def invoice_line(opts \\ []) do
    seed_generator(
      %TheronsErp.Invoices.LineItem{
        price: Money.new(100, :USD),
        quantity: Faker.random_between(1, 10),
        product_id: generate(product()).id
      },
      overrides: opts
    )
  end

  def invoice(opts \\ []) do
    seed_generator(
      %TheronsErp.Invoices.Invoice{
        customer_id: generate(customer()).id,
        state: :draft
      },
      overrides: opts
    )
  end

  def sales_order(opts \\ []) do
    seed_generator(
      %TheronsErp.Sales.SalesOrder{
        customer_id: generate(customer()).id,
        state: :draft
      },
      overrides: opts
    )
  end

  def address(opts \\ []) do
    seed_generator(
      %TheronsErp.People.Address{
        address: Faker.Address.street_address(),
        city: Faker.Address.city(),
        state: Faker.Address.state(),
        zip_code: Faker.Address.zip_code(),
        phone: Faker.Phone.EnUs.phone()
      },
      overrides: opts
    )
  end

  def customer(opts \\ []) do
    seed_generator(
      %TheronsErp.People.Entity{
        name: Faker.Person.name()
      },
      overrides: opts
    )
  end

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
