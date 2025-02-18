defmodule TheronsErpWeb.ProductLiveTest do
  use TheronsErpWeb.ConnCase

  import Phoenix.LiveViewTest
  import TheronsErp.Generator
  import TheronsErp.InventoryFixtures
  import TheronsErp.Generator

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_records(_) do
    product = generate(product())
    product_category = generate(product_category())

    product_category_parent =
      generate(product_category(product_category_id: product_category.id))

    %{product: product, product_category: product_category}
  end

  describe "Index" do
    setup [:create_records]

    test "lists all products", %{conn: conn, product: product} do
      {:ok, _index_live, html} = live(conn, ~p"/products")

      assert html =~ "Listing Products"
      assert html =~ product.name
    end

    test "saves new product", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      assert {:error, {:live_redirect, %{to: path}}} =
               result =
               index_live |> element("a", "New Product") |> render_click()

      assert path =~ ~r"\/products\/[a-z1-9\-]+.*"

      {:ok, view, html} = follow_redirect(result, conn)
      assert html =~ "New Product"

      assert view
             |> form("#product-inline-form", product: @invalid_attrs)
             |> render_change() =~
               "is required"

      assert view
             |> form("#product-inline-form", product: @create_attrs)
             |> render_submit()

      {path, _flash} = assert_redirect(view)
      assert path =~ ~r"\/products\/[a-z1-9\-]+.*"
      {:ok, view, html} = follow_redirect(result, conn)

      html = render(view)
      assert html =~ "some name"
    end

    test "deletes product in listing", %{conn: conn, product: product} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      assert index_live |> element("#products-#{product.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#products-#{product.id}")
    end
  end

  describe "Show" do
    setup [:create_records]

    test "displays product", %{conn: conn, product: product} do
      {:ok, _show_live, html} = live(conn, ~p"/products/#{product}")

      assert html =~ "Show Product"
      assert html =~ product.name
    end

    test "updates product inline", %{
      conn: conn,
      product: product,
      product_category: product_category
    } do
      {:ok, show_live, _html} = live(conn, ~p"/products/#{product}")

      assert show_live
             |> form("#product-inline-form", product: @invalid_attrs)
             |> render_change() =~ "is required"

      assert {:error, {:redirect, %{to: path}}} =
               result =
               show_live
               |> form("#product-inline-form", product: @update_attrs)
               |> render_submit(%{product: %{category_id: product_category.id}})

      {path, _flash} = assert_redirect(show_live)
      assert path =~ ~r"\/products\/#{product.id}.*"
      {:ok, conn} = follow_redirect(result, conn)

      html =
        html_response(conn, 200)

      assert html =~ "Product updated successfully"
      assert html =~ "some updated name"
      assert html =~ product_category.name
    end
  end
end
