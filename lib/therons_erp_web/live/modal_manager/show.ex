defmodule TheronsErpWeb.ModalManager.Show do
  use TheronsErpWeb, :live_view
  alias TheronsErp.Repo
  alias TheronsErp.Inventory

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new_product, _params) do
    socket
    |> assign(:page_title, "New Product")
    |> assign(:modal_title, "New Product")
    |> assign(:changeset, Inventory.change_product(%Inventory.Product{}))
  end

  defp apply_action(socket, :new_category, _params) do
    socket
    |> assign(:page_title, "New Category")
    |> assign(:modal_title, "New Category")
    |> assign(:changeset, Inventory.change_product_category(%Inventory.ProductCategory{}))
  end
end
