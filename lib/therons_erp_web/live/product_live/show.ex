defmodule TheronsErpWeb.ProductLive.Show do
  use TheronsErpWeb, :live_view

  alias TheronsErp.Inventory

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:product, Inventory.get_product!(id))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, _params) do
    socket
  end

  defp apply_action(socket, :new_category, _params) do
    socket
    |> assign(:product_category, %Inventory.ProductCategory{})
  end

  defp page_title(:show), do: "Show Product"
  defp page_title(:edit), do: "Edit Product"
  defp page_title(:new_category), do: "New Category"
end
