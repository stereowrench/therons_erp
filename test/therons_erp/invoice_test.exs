defmodule TheronsErp.InvoiceTest do
  use TheronsErp.DataCase
  alias TheronsErp.Sales
  alias TheronsErp.Inventory
  alias TheronsErp.Sales.{SalesLine}
  alias TheronsErp.Invoices.Invoice

  test "copying line items" do
    sales_order = Sales.create_draft!()

    product =
      Inventory.create_product!("Test Product", Money.new(100, :USD), %{cost: Money.new(50, :USD)})

    sales_line =
      SalesLine
      |> Ash.Changeset.for_create(:create, %{
        sales_order_id: sales_order.id,
        product_id: product.id,
        quantity: 1
      })
      |> Ash.create!()

    invoice =
      Invoice
      |> Ash.Changeset.for_create(:create, %{
        sales_order_id: sales_order.id,
        sales_lines: [sales_line]
      })
      |> Ash.create!()
      |> Ash.load!(:line_items)

    [line_item] = invoice.line_items
    assert line_item.product_id == product.id
    assert Money.equal?(line_item.price, sales_line.sales_price)
    assert line_item.quantity == sales_line.quantity
  end
end
