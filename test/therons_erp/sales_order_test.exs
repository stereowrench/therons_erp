defmodule TheronsErp.Sales.SalesOrderTest do
  use TheronsErp.DataCase
  import TheronsErp.Generator

  test "default pull location is set" do
    sales_order = generate(sales_order())
    product = generate(product())
    sales_line = generate(sales_line(sales_order_id: sales_order.id, product_id: product.id))
    sales_line = Ash.load!(sales_line, :pull_location)

    assert sales_line.pull_location.name == "warehouse.storage"
  end
end
