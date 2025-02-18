defmodule TheronsErpWeb.InvoicesLive.Show do
  alias TheronsErpWeb.Breadcrumbs
  use TheronsErpWeb, :live_view
  import TheronsErpWeb.Selects
  import TheronsErpWeb.Layouts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Invoice {@invoice.identifier} for {@invoice.customer.name}
      </.header>
      <table class="invoice-table">
        <thead>
          <tr>
            <th>Product</th>
            <th>Price</th>
            <th>Quantity</th>
            <th>Total Price</th>
          </tr>
        </thead>
        <tbody>
          <%= for line_item <- @invoice.line_items do %>
            <tr>
              <td>
                <.link
                  navigate={
                    TheronsErpWeb.Breadcrumbs.navigate_to_url(
                      @breadcrumbs,
                      {"products", line_item.product.id, ""},
                      {"invoices", @invoice.id, @invoice.identifier}
                    )
                  }
                  class="text-blue-600"
                >
                  {line_item.product.name}
                </.link>
              </td>
              <td>{line_item.price}</td>
              <td>{line_item.quantity}</td>
              <td>{line_item.total_price}</td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id} = params, _, socket) do
    invoice = load_by_id(id)

    {:noreply, socket |> assign(:invoice, invoice)}
  end

  defp load_by_id(id) do
    Ash.get!(TheronsErp.Invoices.Invoice, id,
      load: [:customer, line_items: [:product, :total_price]]
    )
  end
end
