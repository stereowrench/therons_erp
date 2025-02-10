defmodule TheronsErpWeb.SalesOrderLive.Show do
  use TheronsErpWeb, :live_view
  import TheronsErpWeb.Selects

  @impl true
  def render(assigns) do
    ~H"""
    <.simple_form for={@form} id="sales_order-form" phx-change="validate" phx-submit="save">
      <.header>
        Sales order {@sales_order.identifier}
        <PC.badge color="info">{@sales_order.state}</PC.badge>
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
        <:subtitle>
          <math>
            <mfrac>
              <mn>{@sales_order.total_cost}</mn>
              <mn>{@sales_order.total_price}</mn>
            </mfrac>
            <mo>=</mo>
            <mn>
              {if @sales_order.total_cost not in [nil, Money.new(0, :USD)],
                do:
                  (Decimal.mult(
                     Money.div!(@sales_order.total_price, @sales_order.total_cost.amount).amount,
                     100
                   )
                   |> Decimal.sub(100)
                   |> Decimal.to_string()) <>
                    "%",
                else: "undefined"}
            </mn>
          </math>
        </:subtitle>

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
        <thead>
          <tr>
            <th>Product</th>
            <th>Quantity</th>
            <th>Sales Price</th>
            <th>Unit Price</th>
            <th>Total</th>
          </tr>
        </thead>
        <tbody>
          <.inputs_for :let={sales_line} field={@form[:sales_lines]}>
            <tr>
              <td>
                <.live_select
                  field={sales_line[:product_id]}
                  options={
                    @default_products[Phoenix.HTML.Form.input_value(sales_line, :product_id)] || []
                  }
                  inline={true}
                  update_min_len={0}
                  phx-focus="set-default"
                  container_class="inline-container"
                  text_input_class="inline-text-input"
                  dropdown_class="inline-dropdown"
                  label=""
                >
                  <:option :let={opt}>
                    <.highlight matches={opt.matches} string={opt.label} value={opt.value} />
                  </:option>
                  <:inject_adjacent>
                    <%= if Phoenix.HTML.Form.input_value(sales_line, :product_id) do %>
                      <span class="link-to-inside-field">
                        <.link navigate={
                          TheronsErpWeb.Breadcrumbs.navigate_to_url(
                            @breadcrumbs,
                            {"products", Phoenix.HTML.Form.input_value(sales_line, :product_id), ""},
                            {"sales_orders", @sales_order.id, @params, @sales_order.identifier}
                          )
                        }>
                          <.icon name="hero-arrow-right" />
                        </.link>
                      </span>
                    <% end %>
                  </:inject_adjacent>
                </.live_select>
              </td>
              <td>
                <.input field={sales_line[:quantity]} type="number" />
              </td>
              <td>
                <.input
                  field={sales_line[:sales_price]}
                  value={do_money(sales_line[:sales_price])}
                  type="number"
                />
              </td>
              <td>
                <.input
                  field={sales_line[:unit_price]}
                  value={do_money(sales_line[:unit_price])}
                  type="number"
                />
              </td>
              <td>
                <.input
                  field={sales_line[:total_price]}
                  value={
                    IO.inspect(do_money(sales_line[:total_price])) ||
                      do_money(sales_line[:calculated_total])
                  }
                  type="number"
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

  defp load_by_id(id, socket) do
    Ash.get!(TheronsErp.Sales.SalesOrder, id,
      actor: socket.assigns.current_user,
      load: [:total_price, :total_cost, sales_lines: [:total_price, :product]]
    )
  end

  @impl true
  def handle_params(%{"id" => id} = params, _, socket) do
    sales_order = load_by_id(id, socket)

    default_products =
      for line_item <- sales_order.sales_lines, into: %{} do
        prod = line_item.product

        {prod.id, [%{value: prod.id, label: prod.name, matches: []}]}
      end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(
       :sales_order,
       sales_order
     )
     |> assign(:args, params["args"])
     |> assign(:from_args, params["from_args"])
     |> assign(:params, params)
     |> assign(:default_products, default_products)
     |> assign(:drop_sales, 0)
     |> assign_form()}
  end

  defp page_title(:show), do: "Show Sales order"
  defp page_title(:edit), do: "Edit Sales order"

  @impl true
  def handle_event("validate", %{"sales_order" => sales_order_params} = params, socket) do
    if sales_order_params["product_id"] == "create" do
      # TODO implement create
      IO.inspect(params)
      {:noreply, socket}
    else
      form = AshPhoenix.Form.validate(socket.assigns.form, sales_order_params)
      drop = length(sales_order_params["_drop_sales_lines"] || [])

      {:noreply,
       assign(socket, form: form)
       |> assign(:unsaved_changes, form.source.changed? || drop > 0)
       |> assign(:params, sales_order_params)
       |> assign(:drop_sales, drop)}
    end
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
            load_by_id(socket.assigns.sales_order.id, socket)
          )
          |> assign_form()

        # |> push_patch(to: socket.assigns.patch)

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp assign_form(
         %{assigns: %{sales_order: sales_order, args: args, from_args: from_args}} = socket
       ) do
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

    form =
      case {args, from_args} do
        {nil, nil} -> form
        {_, nil} -> AshPhoenix.Form.validate(form, args)
        {nil, _} -> AshPhoenix.Form.validate(form, from_args)
        _ -> AshPhoenix.Form.validate(form, Map.merge(args, from_args))
      end

    socket
    |> assign(form: to_form(form))
    |> assign(:unsaved_changes, form.changed?)
  end

  defp parse_select_id!(id) do
    [_, number] =
      Regex.run(~r/sales_order\[sales_lines\]\[(\d+)\]_product_id_live_select_component/, id)

    number
  end

  def handle_event(
        "live_select_change",
        %{"text" => text, "id" => id},
        socket
      ) do
    opts =
      get_products("")
      |> prepare_matches(text)

    send_update(LiveSelect.Component, id: id, options: opts)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "set-default",
        %{"id" => id},
        socket
      ) do
    number = parse_select_id!(id)

    if pid =
         socket.assigns.from_args["product_id"] && socket.assigns.from_args["line_id"] == number do
      opts = get_initial_product_options(pid)

      send_update(LiveSelect.Component,
        options: opts,
        id: id,
        value: pid
      )
    else
      value =
        socket.assigns.form
        |> Phoenix.HTML.Form.input_value(:sales_lines)
        |> Enum.at(String.to_integer(number))
        |> Phoenix.HTML.Form.input_value(:product_id)

      if value not in [nil, ""] do
        products = get_products(value)
        text = Enum.find(products, &(&1.value == value)).label
        opts = prepare_matches(products, text)

        send_update(LiveSelect.Component,
          options: opts,
          id: id,
          value: value
        )
      else
        products = get_products("")

        send_update(LiveSelect.Component,
          options: products,
          id: id,
          value: nil
        )
      end
    end

    {:noreply, socket}
  end
end
