defmodule TheronsErpWeb.ProductCategoryLiveTest do
  use TheronsErpWeb.ConnCase

  import Phoenix.LiveViewTest
  import TheronsErp.Generator
  import TheronsErp.InventoryFixtures

  import TheronsErp.Generator

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

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
      {:ok, index_live, _html} = live(conn, ~p"/product_categories")

      assert {:error, {:live_redirect, %{to: path}}} =
               result =
               index_live |> element("a", "New Product category") |> render_click()

      assert path =~ ~r"\/product_categories\/[a-z1-9\-]+.*"

      {:ok, view, html} = follow_redirect(result, conn)
      assert html =~ "New Category"

      assert view
             |> form("#product-category-inline-form", product_category: @invalid_attrs)
             |> render_change() =~ "is required"

      assert view
             |> form("#product-category-inline-form", product_category: @create_attrs)
             |> render_submit()

      {path, _flash} = assert_redirect(view)
      assert path =~ ~r"\/product_categories\/[a-z1-9\-]+.*"
      {:ok, view, html} = follow_redirect(result, conn)

      html = render(view)
      assert html =~ "Product category created successfully"
      assert html =~ "some name"
    end

    test "updates product_category in listing", %{conn: conn, product_category: product_category} do
      {:ok, index_live, _html} = live(conn, ~p"/product_categories")

      assert index_live
             |> element("#product_categories-#{product_category.id} a", "Edit")
             |> render_click() =~
               "Edit Product category"

      assert_patch(index_live, ~p"/product_categories/#{product_category}/edit")

      assert index_live
             |> form("#product_category-form", product_category: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#product_category-form", product_category: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/product_categories")

      html = render(index_live)
      assert html =~ "Product category updated successfully"
      assert html =~ "some updated name"
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
      conn
      |> visit(~p"/product_categories/#{product_category}")
      |> fill_in("Name", with: nil)
      |> submit()
      |> assert_has("input[name='product_category[name]'] ~ p", text: "is required")
      |> fill_in("Name", with: "My Category")
      |> submit()
      |> assert_has(".text-lg", text: "My Category")
      |> fill_in("input", "Parent Category", with: parent_category.id)
      |> submit()
      |> assert_has(".text-lg", text: "#{parent_category.name} / My Category")
    end
  end
end
