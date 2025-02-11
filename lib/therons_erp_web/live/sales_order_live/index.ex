defmodule TheronsErpWeb.SalesOrderLive.Index do
  use TheronsErpWeb, :live_view
  import TheronsErpWeb.Layouts

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Sales orders
      <:actions>
        <.link patch={~p"/sales_orders/new"}>
          <.button>New Sales order</.button>
        </.link>
      </:actions>
    </.header>

    <.table
      id="sales_orders"
      rows={@streams.sales_orders}
      row_click={fn {_id, sales_order} -> JS.navigate(~p"/sales_orders/#{sales_order}") end}
    >
      <:col :let={{_id, sales_order}} label="Id">
        {sales_order.identifier}
        <.status_badge state={sales_order.state} />
      </:col>

      <:col :let={{_id, sales_order}} label="Customer">
        {if sales_order.customer, do: sales_order.customer.name, else: ""}
      </:col>

      <:action :let={{_id, sales_order}}>
        <div class="sr-only">
          <.link navigate={~p"/sales_orders/#{sales_order}"}>Show</.link>
        </div>

        <.link patch={~p"/sales_orders/#{sales_order}/edit"}>Edit</.link>
      </:action>

      <:action :let={{id, sales_order}}>
        <.link
          phx-click={JS.push("delete", value: %{id: sales_order.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="sales_order-modal"
      show
      on_cancel={JS.patch(~p"/sales_orders")}
    >
      <.live_component
        module={TheronsErpWeb.SalesOrderLive.FormComponent}
        id={(@sales_order && @sales_order.id) || :new}
        title={@page_title}
        current_user={@current_user}
        action={@live_action}
        sales_order={@sales_order}
        patch={~p"/sales_orders"}
      />
    </.modal>
    """
  end

  @ash_loads [:customer]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(
       :sales_orders,
       Ash.read!(TheronsErp.Sales.SalesOrder,
         actor: socket.assigns[:current_user],
         load: @ash_loads
       )
     )
     |> assign_new(:current_user, fn -> nil end)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Sales order")
    |> assign(
      :sales_order,
      Ash.get!(TheronsErp.Sales.SalesOrder, id,
        actor: socket.assigns.current_user,
        load: @ash_loads
      )
    )
  end

  defp apply_action(socket, :new, _params) do
    sales_order = TheronsErp.Sales.create_draft!()

    socket
    |> assign(:page_title, "New Sales order")
    |> assign(:sales_order, nil)
    |> push_navigate(to: ~p"/sales_orders/#{sales_order}")
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Sales orders")
    |> assign(:sales_order, nil)
  end

  @impl true
  def handle_info({TheronsErpWeb.SalesOrderLive.FormComponent, {:saved, sales_order}}, socket) do
    {:noreply, stream_insert(socket, :sales_orders, sales_order)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    sales_order = Ash.get!(TheronsErp.Sales.SalesOrder, id, actor: socket.assigns.current_user)
    Ash.destroy!(sales_order, actor: socket.assigns.current_user)

    {:noreply, stream_delete(socket, :sales_orders, sales_order)}
  end
end
