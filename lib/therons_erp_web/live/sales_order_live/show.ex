defmodule TheronsErpWeb.SalesOrderLive.Show do
  use TheronsErpWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.simple_form for={@form} id="sales_order-form" phx-change="validate" phx-submit="save">
      <.header>
        Sales order {@sales_order.id}
        <%= if @unsaved_changes do %>
          <.button phx-disable-with="Saving..." class="save-button">
            <.icon name="hero-check-circle" />
          </.button>

          <%= if @drop_sales > 0 do %>
            <span class="text-sm">
              Delete {@drop_sales} items.
            </span>
          <% end %>
        <% end %>
        <:subtitle>This is a sales_order record from your database.</:subtitle>

        <:actions>
          <%!-- <.link patch={~p"/sales_orders/#{@sales_order}/show/edit"} phx-click={JS.push_focus()}>
            <.button>Edit sales_order</.button>
          </.link> --%>
        </:actions>
      </.header>

      <.list>
        <:item title="Id">{@sales_order.id}</:item>
      </.list>

      <table class="product-category-table">
        <tbody>
          <.inputs_for :let={sales_line} field={@form[:sales_lines]}>
            <tr>
              <td>
                <.input field={sales_line[:quantity]} type="number" label="Quantity" />
              </td>
              <td>
                <.input
                  field={sales_line[:sales_price]}
                  value={do_money(sales_line[:sales_price])}
                  type="number"
                  label="Unit sale price"
                />
              </td>
              <td>
                <.input
                  field={sales_line[:unit_price]}
                  value={do_money(sales_line[:unit_price])}
                  type="number"
                  label="Unit sale price"
                />
              </td>
              <td>
                <label>
                  <input
                    type="checkbox"
                    name={"#{@form.name}[_drop_sales_lines][]"}
                    value={sales_line.index}
                    class="hidden"
                  />

                  <.icon name="hero-x-mark" />
                </label>
              </td>
            </tr>
          </.inputs_for>
        </tbody>
      </table>

      <label>
        <input type="checkbox" name={"#{@form.name}[_add_sales_lines]"} value="end" class="hidden" />
        <.icon name="hero-plus" />
      </label>

      <.back navigate={~p"/sales_orders"}>Back to sales_orders</.back>
    </.simple_form>

    <.modal
      :if={@live_action == :edit}
      id="sales_order-modal"
      show
      on_cancel={JS.patch(~p"/sales_orders/#{@sales_order}")}
    >
      <.live_component
        module={TheronsErpWeb.SalesOrderLive.FormComponent}
        id={@sales_order.id}
        title={@page_title}
        action={@live_action}
        current_user={@current_user}
        sales_order={@sales_order}
        patch={~p"/sales_orders/#{@sales_order}"}
      />
    </.modal>
    """
  end

  defp do_money(field) do
    case field.value do
      nil ->
        ""

      "" ->
        ""

      %Money{} = money ->
        money.amount
        |> Decimal.to_float()

      el ->
        el
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(
       :sales_order,
       Ash.get!(TheronsErp.Sales.SalesOrder, id,
         actor: socket.assigns.current_user,
         load: [:sales_lines]
       )
     )
     |> assign(:drop_sales, 0)
     |> assign_form()}
  end

  defp page_title(:show), do: "Show Sales order"
  defp page_title(:edit), do: "Edit Sales order"

  @impl true
  def handle_event("validate", %{"sales_order" => sales_order_params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, sales_order_params)
    drop = length(sales_order_params["_drop_sales_lines"])

    {:noreply,
     assign(socket, form: form)
     |> assign(:unsaved_changes, form.source.changed? || drop > 0)
     |> assign(:drop_sales, drop)}
  end

  def handle_event("save", %{"sales_order" => sales_order_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: sales_order_params) do
      {:ok, sales_order} ->
        # notify_parent({:saved, sales_order})

        socket =
          socket
          |> put_flash(:info, "Sales order #{socket.assigns.form.source.type}d successfully")
          |> assign(
            :sales_order,
            Ash.get!(TheronsErp.Sales.SalesOrder, socket.assigns.sales_order.id,
              actor: socket.assigns.current_user,
              load: [:sales_lines]
            )
          )
          |> assign_form()

        # |> push_patch(to: socket.assigns.patch)

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

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

    socket
    |> assign(form: to_form(form))
    |> assign(:unsaved_changes, form.changed?)
  end
end
