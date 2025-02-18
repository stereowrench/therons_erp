defmodule TheronsErpWeb.InvoicesLive.Show do
  alias TheronsErpWeb.Breadcrumbs
  use TheronsErpWeb, :live_view
  import TheronsErpWeb.Selects
  import TheronsErpWeb.Layouts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <table>
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
              <td>{line_item.product.name}</td>
              <td>${line_item.price.amount |> Decimal.to_string()}</td>
              <td>{line_item.quantity}</td>
              <td>${line_item.total_price}</td>
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
    Ash.get!(TheronsErp.Invoices.Invoice, id, load: [line_items: [:product]])
  end
end
