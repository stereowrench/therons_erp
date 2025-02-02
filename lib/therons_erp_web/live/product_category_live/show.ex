defmodule TheronsErpWeb.ProductCategoryLive.Show do
  use TheronsErpWeb, :live_view

  alias TheronsErp.Inventory

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:product_category, Inventory.get_product_category!(id))}
  end

  defp page_title(:show), do: "Show Product category"
  defp page_title(:edit), do: "Edit Product category"
end
