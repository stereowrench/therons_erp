defmodule TheronsErpWeb.ProductCategoryLiveTest do
  use TheronsErpWeb.ConnCase

  import Phoenix.LiveViewTest
  import TheronsErp.Generator
  import TheronsErp.InventoryFixtures

  import TheronsErp.Generator

  defp create_records(_) do
    parent_category = generate(product_category())
    product_category = generate(product_category(product_category_id: parent_category.id))
    %{product_category: product_category, parent_category: parent_category}
  end

  describe "Index" do
    setup [:create_records]

    test "lists all product_categories", %{conn: conn, product_category: product_category} do
      {:ok, _index_live, html} = live(conn, ~p"/product_categories")

      assert html =~ "Listing Product categories"
      assert html =~ product_category.name
    end

    test "saves new product_category", %{conn: conn} do
      conn
      |> visit(~p"/product_categories")
      |> click_link("New Product category")
      |> fill_in("Name", with: "Bob's Category")
      |> submit()
      |> assert_has(".text-lg", text: "Bob's Category")
    end

    test "doesn't save invalid category", %{conn: conn} do
      conn
      |> visit(~p"/product_categories")
      |> click_link("New Product category")
      |> fill_in("Name", with: "")
      |> assert_has("input[name='product_category[name]'] ~ p ", text: "is required")
    end

    test "new shows product breadcrumb", %{conn: conn, parent_category: parent_category} do
      conn
      |> visit(~p"/product_categories")
      |> click_link("New Product category")
      |> fill_in("Name", with: "Bob's Category")
      |> submit()
      |> assert_has(".breadcrumbs a", text: "Product Categories")
      |> unwrap(fn view ->
        Phoenix.LiveViewTest.render_submit(element(view, "form"), %{
          product_category: %{
            product_category_id: parent_category.id
          }
        })
      end)
      |> submit()
      |> click_link(".link-to-inside-field > a", "")
      |> assert_has(".breadcrumbs a", text: "Product Categories")
      |> assert_has(".breadcrumbs a", text: "Bob's Category")
    end

    test "deletes product_category in listing", %{conn: conn, product_category: product_category} do
      {:ok, index_live, _html} = live(conn, ~p"/product_categories")

      assert index_live
             |> element("#product_categories-#{product_category.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#product_categories-#{product_category.id}")
    end
  end

  describe "Show" do
    setup [:create_records]

    test "displays product_category", %{conn: conn, product_category: product_category} do
      {:ok, _show_live, html} = live(conn, ~p"/product_categories/#{product_category}")

      assert html =~ "Show Product category"
      assert html =~ product_category.name
    end

    test "updates product_category", %{
      conn: conn,
      product_category: product_category,
      parent_category: parent_category
    } do
      new_parent = generate(product_category())

      conn
      |> visit(~p"/product_categories/#{product_category}")
      |> fill_in("Name", with: nil)
      |> submit()
      |> assert_has("input[name='product_category[name]'] ~ p", text: "is required")
      |> fill_in("Name", with: "My Category")
      |> submit()
      |> assert_has(".text-lg", text: "#{parent_category.name} / My Category")
      |> unwrap(fn view ->
        Phoenix.LiveViewTest.render_submit(element(view, "form"), %{
          product_category: %{
            product_category_id: new_parent.id
          }
        })
      end)
      |> submit()
      |> assert_has(".text-lg", text: "#{new_parent.name} / My Category")
    end
  end
end
