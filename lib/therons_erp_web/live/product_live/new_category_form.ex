defmodule TheronsErpWeb.ProductLive.NewCategoryForm do
  use TheronsErpWeb, :live_component

  alias TheronsErp.Inventory

  def render(assigns) do
    ~H"""
    """
  end

  def update(%{product_category: product_category} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn -> to_form(Inventory.change_product_category(product_category)) end)}
  end

  def handle_event("save", %{"product_category" => product_category_params}, socket) do
    product = socket.assigns.product

    case Inventory.create_product_category(product, product_category_params) do
      {:ok, product_category} ->
        {:noreply,
         socket
         |> put_flash(:info, "Product category created successfully.")
         |> push_redirect(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
    end
  end
end
