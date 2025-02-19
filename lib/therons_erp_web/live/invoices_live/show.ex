defmodule TheronsErpWeb.InvoicesLive.Show do
  alias TheronsErpWeb.Breadcrumbs
  use TheronsErpWeb, :live_view
  import TheronsErpWeb.Selects
  import TheronsErpWeb.Layouts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form for={@form} phx-submit="save" phx-change="validate">
        <.header>
          Invoice {@invoice.identifier} for {@invoice.customer.name}

          <.status_badge state={@invoice.state} />
          <%= if @unsaved_changes do %>
            <.button phx-disable-with="Saving..." class="save-button">
              <.icon name="hero-check-circle" />
            </.button>
          <% end %>
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
                <td>
                  {line_item.price} {render_discount_arrows(
                    line_item.price,
                    line_item.product.sales_price
                  )}
                </td>
                <td>{line_item.quantity}</td>
                <td>{line_item.total_price}</td>
              </tr>
            <% end %>
          </tbody>
        </table>

        <div class="cost-summary">
          <div class="total-price">
            <span class="input-icon">
              <i class="z-10">$</i>
              <.input field={@form[:paid_amount]} type="number" value={@invoice.paid_amount.amount} />
            </span>
          </div>
          <div class="total-cost">
            {@invoice.total_price}
          </div>
          <hr />
        </div>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _, socket) do
    invoice = load_by_id(id)

    {:noreply,
     socket |> assign(:unsaved_changes, false) |> assign(:invoice, invoice) |> assign_form()}
  end

  def handle_event("save", %{"invoice" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
      {:ok, invoice} ->
        {
          :noreply,
          socket
          |> assign(:invoice, invoice)
          |> assign_form()
          |> push_navigate(
            to:
              ~p"/invoices/#{invoice.id}?#{[breadcrumbs: Breadcrumbs.encode_breadcrumbs(socket.assigns.breadcrumbs)]}"
          )
        }

      {:error, form} ->
        {:noreply, socket |> assign(form: to_form(form))}
    end
  end

  @impl true
  def handle_event("validate", %{"invoice" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, params)

    {:noreply,
     socket |> assign(:unsaved_changes, form.source.changed?) |> assign(form: to_form(form))}
  end

  defp assign_form(%{assigns: %{invoice: invoice}} = socket) do
    form =
      AshPhoenix.Form.for_update(invoice, :update,
        as: "invoice",
        actor: socket.assigns.current_user
      )

    socket
    |> assign(form: to_form(form))
  end

  defp load_by_id(id) do
    Ash.get!(TheronsErp.Invoices.Invoice, id,
      load: [:total_price, :customer, line_items: [:product, :total_price]]
    )
  end

  defp render_discount_arrows(line_item_price, product_price) do
    case Money.cmp(line_item_price, product_price) do
      0 -> ""
      -1 -> "↓ (#{Money.to_string!(product_price)})"
      1 -> "↑ (#{Money.to_string!(product_price)})"
    end
  end
end
