defmodule TheronsErpWeb.ProductCategoryLive.FormComponent do
  use TheronsErpWeb, :live_component

  alias TheronsErp.Inventory

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage product_category records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="product_category-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Product category</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{product_category: product_category} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Inventory.change_product_category(product_category))
     end)}
  end

  @impl true
  def handle_event("validate", %{"product_category" => product_category_params}, socket) do
    changeset =
      Inventory.change_product_category(socket.assigns.product_category, product_category_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"product_category" => product_category_params}, socket) do
    save_product_category(socket, socket.assigns.action, product_category_params)
  end

  defp save_product_category(socket, :edit, product_category_params) do
    case Inventory.update_product_category(
           socket.assigns.product_category,
           product_category_params
         ) do
      {:ok, product_category} ->
        notify_parent({:saved, product_category})

        {:noreply,
         socket
         |> put_flash(:info, "Product category updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_product_category(socket, :new, product_category_params) do
    case Inventory.create_product_category(product_category_params) do
      {:ok, product_category} ->
        notify_parent({:saved, product_category})

        {:noreply,
         socket
         |> put_flash(:info, "Product category created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
