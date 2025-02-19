defmodule TheronsErpWeb.InvoicesLive.Index do
  use TheronsErpWeb, :live_view
  import TheronsErpWeb.Layouts
  alias TheronsErpWeb.Breadcrumbs

  @impl true
  def render(assigns) do
    ~H"""
    <.table
      id="invoices"
      rows={@streams.invoices}
      row_click={
        fn {_id, invoice} ->
          JS.navigate(
            Breadcrumbs.navigate_to_url(
              @breadcrumbs,
              {"invoices", invoice.id, invoice.identifier},
              {"invoices"}
            )
          )
        end
      }
    >
      <:col :let={{_id, invoice}} label="Id">
        I{invoice.identifier}
        <.status_badge state={invoice.state} />
      </:col>

      <:col :let={{_id, invoice}} label="Customer">
        {invoice.customer.name}
      </:col>

      <:action :let={{_id, invoice}}>
        <div class="sr-only">
          <.link navigate={
            Breadcrumbs.navigate_to_url(
              @breadcrumbs,
              {"invoices", invoice.id, invoice.identifier},
              {"invoices"}
            )
          }>
            Show
          </.link>
        </div>
      </:action>

      <:action :let={{id, invoice}}>
        <.link
          phx-click={JS.push("delete", value: %{id: invoice.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>
    """
  end

  @ash_loads [:customer]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(
       :invoices,
       Ash.read!(TheronsErp.Invoices.Invoice,
         actor: socket.assigns[:current_user],
         load: @ash_loads
       )
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _) do
    socket
    |> assign(:page_title, "Listing invoices")
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    invoicw = Ash.get!(TheronsErp.Invoices.Invoice, id, actor: socket.assigns.current_user)
    Ash.destroy!(invoicw, actor: socket.assigns.current_user)

    {:noreply, stream_delete(socket, :invoices, invoicw)}
  end
end
