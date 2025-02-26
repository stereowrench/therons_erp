defmodule TheronsErp.Sales.SalesOrderTest do
  use TheronsErp.DataCase
  import TheronsErp.Generator

  test "pull location is set" do
    sales_order = generate(sales_order())
    sales_order = Ash.load!(sales_order, [:pull_location])
    assert sales_order.pull_location.name == "warehouse.storage"
  end
end
