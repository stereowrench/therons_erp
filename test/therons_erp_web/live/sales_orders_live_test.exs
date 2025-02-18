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
  end

  test "Sales order line items", %{conn: conn} do
    customer = generate(customer())
    address = generate(address(entity_id: customer.id))
    sales_order = generate(sales_order(address_id: address.id, customer_id: customer.id))
    product = generate(product())

    conn
    |> visit(~p"/sales_orders/#{sales_order.id}")
    |> fill_in(".test-hack", "Test Hack", with: "")
    |> unwrap(fn view ->
      Phoenix.LiveViewTest.render_change(
        Phoenix.LiveViewTest.element(view, "form"),
        %{
          "_target" => ["sales_order", "sales_lines"],
          "sales_order" => %{"_add_sales_lines" => "end"}
        }
      )
    end)
    |> submit()
    |> assert_has("p", text: "is required")
    |> unwrap(fn view ->
      Phoenix.LiveViewTest.render_change(
        Phoenix.LiveViewTest.element(view, "form"),
        %{
          "_target" => ["sales_order", "sales_lines"],
          "sales_order" => %{
            "sales_lines" => %{
              "0" => %{
                "product_id" => product.id,
                "quantity" => "1",
                "sales_price" => "2",
                "total_cost" => "1",
                "total_price" => "2",
                "unit_price" => "1"
              }
            }
          }
        }
      )
    end)
    |> submit()
    |> refute_has("p", text: "is required")
  end

  test "Sales order draft -> ready", %{conn: conn} do
    customer = generate(customer())
    address = generate(address(entity_id: customer.id))
    sales_order = generate(sales_order(address_id: address.id, customer_id: customer.id))

    conn
    |> visit(~p"/sales_orders/#{sales_order.id}")
    |> click_button("Ready")
    |> assert_has("badge", text: "Ready")
  end

  test "Sales order ready -> invoice", %{conn: conn} do
    customer = generate(customer())
    address = generate(address(entity_id: customer.id))

    sales_order =
      generate(sales_order(address_id: address.id, customer_id: customer.id, state: :ready))

    conn
    |> visit(~p"/sales_orders/#{sales_order.id}")
    |> assert_has("badge", text: "Ready")
    |> click_button("Generate invoice")
    |> assert_has("badge", text: "invoiced")
  end
end
