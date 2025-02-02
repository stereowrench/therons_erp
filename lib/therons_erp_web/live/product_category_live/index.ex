defmodule TheronsErpWeb.ProductCategoryLive.Index do
  use TheronsErpWeb, :live_view

  alias TheronsErp.Inventory
  alias TheronsErp.Inventory.ProductCategory

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :product_categories, Inventory.list_product_categories())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Product category")
    |> assign(:product_category, Inventory.get_product_category!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Product category")
    |> assign(:product_category, %ProductCategory{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Product categories")
    |> assign(:product_category, nil)
  end

  @impl true
  def handle_info({TheronsErpWeb.ProductCategoryLive.FormComponent, {:saved, product_category}}, socket) do
    {:noreply, stream_insert(socket, :product_categories, product_category)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product_category = Inventory.get_product_category!(id)
    {:ok, _} = Inventory.delete_product_category(product_category)

    {:noreply, stream_delete(socket, :product_categories, product_category)}
  end
end
