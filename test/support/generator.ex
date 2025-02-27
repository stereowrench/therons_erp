defmodule TheronsErp.Generator do
  use Ash.Generator

  def replenishment(opts \\ []) do
    changeset_generator(
      TheronsErp.Purchasing.Replenishment,
      :create,
      defaults: [
        product_id: nil,
        vendor_id: nil,
        quantity_multiple: 1,
        price: Money.new(0, :XIT),
        trigger_quantity: 10,
        lead_time_days: 1
      ],
      overrides: opts
    )
  end

  def vendor(opts \\ []) do
    changeset_generator(
      TheronsErp.Purchasing.Vendor,
      :create,
      defaults: [
        name: Faker.Person.name()
      ],
      overrides: opts
    )
  end

  def purchase_order(opts \\ []) do
    changeset_generator(
      TheronsErp.Purchasing.PurchaseOrder,
      :create,
      defaults: [
        order_date: MyDate.today(),
        delivery_date: MyDate.today(),
        total_amount: Money.new(100, :USD)
      ],
      overrides: opts
    )
  end

  def purchase_order_item(opts \\ []) do
    changeset_generator(
      TheronsErp.Purchasing.PurchaseOrderItem,
      :create,
      defaults: [
        quantity: Faker.random_between(1, 10),
        product_id: generate(product()).id,
        unit_price: Money.new(10, :USD)
      ],
      overrides: opts
    )
  end

  def location(opts \\ []) do
    changeset_generator(
      TheronsErp.Inventory.Location,
      :create,
      defaults: [
        name: sequence(:location, &"Location #{&1}")
      ],
      overrides: opts
    )
  end

  def product_routes(opts \\ []) do
    changeset_generator(
      TheronsErp.Inventory.ProductRoutes,
      :create,
      defaults: [
        product_id: nil,
        routes_id: nil
      ],
      overrides: opts
    )
  end

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

  def sales_line(opts \\ []) do
    changeset_generator(
      TheronsErp.Sales.SalesLine,
      :create,
      defaults: [
        unit_price: nil,
        pull_location_id: nil,
        sales_price: nil
      ],
      overrides: opts
    )
  end

  def sales_order(opts \\ []) do
    changeset_generator(
      TheronsErp.Sales.SalesOrder,
      :create,
      defaults: [
        customer_id: generate(customer()).id,
        address_id: nil,
        state: :draft
      ],
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
