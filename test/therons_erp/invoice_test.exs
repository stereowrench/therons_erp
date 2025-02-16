defmodule TheronsErp.InvoiceTest do
  use TheronsErp.DataCase
  alias TheronsErp.Sales
  alias TheronsErp.Inventory
  alias TheronsErp.Sales.{SalesOrder, SalesLine}

  test "copying line items" do
    sales_order = Sales.create_draft()
    product = Inventory.create_product(%{name: "Test Product", sales_price: 100, cost: 50})
    sales_line = Ash.create!(SalesLine, %{sales_order_id: sales_order.id, product_id: product.id, quantity: 1})

    invoice = Ash.create!(Invoice, %{sales_order_id: sales_order.id, sales_lines: [sales_line]})

    [line_item] = invoice.line_items
    assert line_item.product_id == product.id
    assert Money.equal?(line_item.price, sales_line.sales_price)
    assert Money.equal?(line_item.quantity, sales_line.quantity)
  end
end
