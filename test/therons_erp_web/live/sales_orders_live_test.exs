defmodule TheronsErpWeb.SalesOrdersLiveTest do
  use TheronsErpWeb.ConnCase
  import TheronsErp.Generator

  alias Phoenix.LiveViewTest

  test "Sales order can be created", %{conn: conn} do
    customer = generate(customer())

    conn
    |> visit(~p"/sales_orders")
    |> click_link("New Sales order")
    |> fill_in(".test-hack", "Test Hack", with: "")
    |> unwrap(fn view ->
      Phoenix.LiveViewTest.render_submit(LiveViewTest.element(view, "form"), %{
        sales_order: %{
          customer_id: customer.id
        }
      })
    end)
    # It would be nice to check if we get an error when there's no customer but that's not how this is.
    |> submit()
    |> select("Create new", from: "Address")
    |> fill_in("Address", with: "101 N St")
    |> fill_in("Address2", with: "Apt 41")
    |> fill_in("City", with: "Austin")
    |> select("TX", from: "State")
    |> fill_in("Zip code", with: "78704")
    |> fill_in("Phone", with: "555-555-5555")
    |> submit()
    |> PhoenixTest.open_browser()
  end

  test "Sales order line items"
  test "Sales order draft -> ready"
  test "Sales order ready -> invoice"
  test "Sales order breadcrumbs"
end
