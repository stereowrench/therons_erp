defmodule TheronsErpWeb.SalesOrderLive.FormComponent do
  use TheronsErpWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage sales_order records in your database.</:subtitle>
      </.header>
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
  def handle_event("validate", %{"sales_order" => sales_order_params}, socket) do
    {:noreply,
     assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, sales_order_params))}
  end

  def handle_event("save", %{"sales_order" => sales_order_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: sales_order_params) do
      {:ok, sales_order} ->
        notify_parent({:saved, sales_order})

        socket =
          socket
          |> put_flash(:info, "Sales order #{socket.assigns.form.source.type}d successfully")
          |> push_patch(to: socket.assigns.patch)

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{sales_order: sales_order}} = socket) do
    form =
      if sales_order do
        AshPhoenix.Form.for_update(sales_order, :update,
          as: "sales_order",
          actor: socket.assigns.current_user
        )
      else
        AshPhoenix.Form.for_create(TheronsErp.Sales.SalesOrder, :create,
          as: "sales_order",
          actor: socket.assigns.current_user
        )
      end

    assign(socket, form: to_form(form))
  end
end
