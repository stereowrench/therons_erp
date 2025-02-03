defmodule TheronsErpWeb.ProductCategoryLive.FormComponent do
  use TheronsErpWeb, :live_component

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
        <%= if @form.source.type == :create do %>
          <.input field={@form[:name]} type="text" label="Name" /><.input
            field={@form[:product_category_id]}
            type="text"
            label="Product category"
          />
        <% end %>
        <%= if @form.source.type == :update do %>
          <.input field={@form[:product_category_id]} type="text" label="Product category" />
        <% end %>

        <:actions>
          <.button phx-disable-with="Saving...">Save Product category</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_form()}
  end

  @impl true
  def handle_event("validate", %{"product_category" => product_category_params}, socket) do
    {:noreply,
     assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, product_category_params))}
  end

  def handle_event("save", %{"product_category" => product_category_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: product_category_params) do
      {:ok, product_category} ->
        notify_parent({:saved, product_category})

        socket =
          socket
          |> put_flash(:info, "Product category #{socket.assigns.form.source.type}d successfully")
          |> push_patch(to: socket.assigns.patch)

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{product_category: product_category}} = socket) do
    form =
      if product_category do
        AshPhoenix.Form.for_update(product_category, :update_parent,
          as: "product_category",
          actor: socket.assigns.current_user
        )
      else
        AshPhoenix.Form.for_create(TheronsErp.Inventory.ProductCategory, :create,
          as: "product_category",
          actor: socket.assigns.current_user
        )
      end

    assign(socket, form: to_form(form))
  end
end
