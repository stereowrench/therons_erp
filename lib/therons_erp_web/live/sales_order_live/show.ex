defmodule TheronsErpWeb.SalesOrderLive.Show do
  alias TheronsErpWeb.Breadcrumbs
  use TheronsErpWeb, :live_view
  import TheronsErpWeb.Selects
  import TheronsErpWeb.Layouts

  # TODO address should be selectable when customer is changed but not persisted
  # TODO address should be reset when customer changed

  @impl true
  def render(assigns) do
    ~H"""
    <.simple_form for={@form} id="sales_order-form" phx-change="validate" phx-submit="save">
      <.header>
        Sales order {@sales_order.identifier}
        <.status_badge state={@sales_order.state} />
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

        <:actions>
          <%= if @sales_order.state == :draft and not @unsaved_changes do %>
            <.button phx-disable-with="Saving..." phx-click="set-ready">
              Ready
            </.button>
          <% end %>
          <%= if @sales_order.state == :ready do %>
            <.button phx-disable-with="Saving..." phx-click="set-draft">
              Return to draft
            </.button>
          <% end %>
        </:actions>
        <:subtitle>
          Margin:
          <math>
            <mfrac>
              <mn>{@sales_order.total_cost}</mn>
              <mn>{@sales_order.total_price}</mn>
            </mfrac>
            <mo>=</mo>
            <mn>
              {if @sales_order.total_cost != nil and
                    not Money.equal?(@sales_order.total_cost, Money.new(0, :USD)),
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
      </.header>

      <div class="prose">
        <h2>Customer</h2>

        <.live_select
          field={@form[:customer_id]}
          options={@default_customers}
          inline={true}
          update_min_len={0}
          phx-focus="set-default-customers"
          container_class="inline-container"
          text_input_class="inline-text-input"
          dropdown_class="inline-dropdown"
          label="Customer"
        >
          <:option :let={opt}>
            <.highlight matches={opt.matches} string={opt.label} value={opt.value} />
          </:option>
          <:inject_adjacent>
            <%= if Phoenix.HTML.Form.input_value(@form, :customer_id) do %>
              <span class="link-to-inside-field">
                <.link navigate={
                  TheronsErpWeb.Breadcrumbs.navigate_to_url(
                    @breadcrumbs,
                    {"entities", Phoenix.HTML.Form.input_value(@form, :customer_id), ""},
                    {"sales_orders", @sales_order.id, @params, @sales_order.identifier}
                  )
                }>
                  <.icon name="hero-arrow-right" />
                </.link>
              </span>
            <% end %>
          </:inject_adjacent>
        </.live_select>

        <%= if Phoenix.HTML.Form.input_value(@form, :customer_id) do %>
          <div class="inline-container address-container">
            <.input
              field={@form[:address_id]}
              type="select"
              label="Address"
              options={
                [{"Unselected", nil}] ++
                  Enum.map(@addresses, &{&1.address, &1.id}) ++
                  [{"Create new", "create"}]
              }
            />
          </div>
          <span class="link-to-inside-field address-link">
            <.link navigate={
              TheronsErpWeb.Breadcrumbs.navigate_to_url(
                @breadcrumbs,
                {"entities", Phoenix.HTML.Form.input_value(@form, :customer_id), ""},
                {"sales_orders", @sales_order.id, @params, @sales_order.identifier}
              )
            }>
              <.icon name="hero-arrow-right" />
            </.link>
          </span>
        <% end %>

        <%!-- Render address --%>
        <%= if get_address(@form, @addresses) do %>
          <div>
            <label class="fieldsetlikelabel">Address</label>
            <div class="fieldsetlike">
              <div class="address">
                <%!-- Address 1 --%>
                <div class="address-line">
                  <span>
                    <%!-- Address label --%>
                    <span class="text-xs">Address</span>
                    {get_address(@form, @addresses).address}
                  </span>
                </div>
                <%!-- Address 2 --%>
                <div class="address2-line">
                  <span>
                    <span class="text-xs">Address 2</span>
                    {get_address(@form, @addresses).address2}
                  </span>
                </div>
                <div class="address-city-state-zip">
                  <%!-- City --%>
                  <div class="city-line">
                    <span class="text-xs">City</span>
                    {get_address(@form, @addresses).city}
                  </div>
                  <%!-- State --%>
                  <div class="state-line">
                    <span class="text-xs">State</span>
                    {get_address(@form, @addresses).state}
                  </div>
                  <%!-- Zip Code --%>
                  <div class="zip-line">
                    <span class="text-xs">Zip Code</span>
                    {get_address(@form, @addresses).zip_code}
                  </div>
                </div>
                <%!-- Phone number --%>
                <div class="phone-line">
                  <span class="text-xs">Phone Number</span>
                  {get_address(@form, @addresses).phone}
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <table class="product-category-table">
        <thead>
          <tr>
            <th>Product</th>
            <th>Quantity</th>
            <th>Sales Price</th>
            <th>Unit Price</th>
            <th>Total Price</th>
            <th>Total Cost</th>
          </tr>
        </thead>
        <tbody>
          <%= if @sales_order.state == :draft do %>
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
                              {"products", Phoenix.HTML.Form.input_value(sales_line, :product_id),
                               ""},
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
                  <span class="input-icon">
                    <i class="z-10">$</i>
                    <.input
                      field={sales_line[:sales_price]}
                      value={do_money(sales_line[:sales_price])}
                      type="number"
                      inline_container={true}
                    />
                    <%= if to_string(Phoenix.HTML.Form.input_value(sales_line, :sales_price)) != (if p = Phoenix.HTML.Form.input_value(sales_line, :product), do: to_string(p.sales_price), else: "")do %>
                      <.button
                        phx-disable-with="Saving..."
                        class="revert-button"
                        name="revert"
                        value={"revert-price-#{sales_line.index}"}
                      >
                        <.icon name="hero-arrow-uturn-left" />
                      </.button>
                    <% end %>
                  </span>
                </td>
                <td>
                  <span class="input-icon">
                    <i class="z-10">$</i>
                    <.input
                      field={sales_line[:unit_cost]}
                      value={do_money(sales_line[:unit_cost])}
                      type="number"
                      inline_container={true}
                    />
                    <%= if to_string(Phoenix.HTML.Form.input_value(sales_line, :unit_cost)) != (if p = Phoenix.HTML.Form.input_value(sales_line, :product), do: to_string(p.cost), else: "")do %>
                      <.button
                        phx-disable-with="Saving..."
                        class="revert-button"
                        name="revert"
                        value={"revert-cost-#{sales_line.index}"}
                      >
                        <.icon name="hero-arrow-uturn-left" />
                      </.button>
                    <% end %>
                  </span>
                </td>
                <td>
                  <span class="input-icon">
                    <i class="z-10">$</i>
                    <.input
                      field={sales_line[:total_price]}
                      value={
                        active_price_for_sales_line(
                          sales_line,
                          sales_line.index,
                          @total_price_changes
                        )
                      }
                      type="number"
                      inline_container={true}
                    />
                    <%= if (@total_price_changes[to_string(sales_line.index)] == true) || is_active_price_persisted?(sales_line, sales_line.index, @total_price_changes) do %>
                      <.button
                        phx-disable-with="Saving..."
                        class="revert-button"
                        name="revert"
                        value={"revert-total-price-#{sales_line.index}"}
                      >
                        <.icon name="hero-arrow-uturn-left" />
                      </.button>
                    <% end %>
                  </span>
                </td>
                <td>
                  <span class="input-icon">
                    <i class="z-10">$</i>
                    <.input
                      field={sales_line[:total_cost]}
                      value={
                        total_cost_for_sales_line(sales_line, sales_line.index, @total_cost_changes)
                      }
                      type="number"
                      inline_container={true}
                    />
                    <%= if (@total_cost_changes[to_string(sales_line.index)] == true) || is_total_cost_persisted?(sales_line, sales_line.index, @total_cost_changes) do %>
                      <.button
                        phx-disable-with="Saving..."
                        class="revert-button"
                        name="revert"
                        value={"revert-total-cost-#{sales_line.index}"}
                      >
                        <.icon name="hero-arrow-uturn-left" />
                      </.button>
                    <% end %>
                  </span>
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
          <% else %>
            <%= for sales_line <- @sales_order.sales_lines do %>
              <tr>
                <td>
                  <.link
                    navigate={
                      TheronsErpWeb.Breadcrumbs.navigate_to_url(
                        @breadcrumbs,
                        {"products", sales_line.product.id, ""},
                        {"sales_orders", @sales_order.id, @params, @sales_order.identifier}
                      )
                    }
                    class="text-blue-600"
                  >
                    {sales_line.product.name}
                  </.link>
                </td>
                <td>
                  {sales_line.quantity}
                </td>
                <td>
                  $ {sales_line.sales_price.amount |> Decimal.to_float()}
                </td>
                <td>
                  $ {sales_line.unit_price.amount |> Decimal.to_float()}
                </td>
                <td>
                  $ {sales_line.active_price.amount |> Decimal.to_float()}
                </td>
                <td>
                  $ {sales_line.total_cost.amount |> Decimal.to_float()}
                </td>
              </tr>
            <% end %>
          <% end %>
        </tbody>
      </table>

      <%= if @sales_order.state == :draft do %>
        <label>
          <input type="checkbox" name={"#{@form.name}[_add_sales_lines]"} value="end" class="hidden" />
          <.icon name="hero-plus" />
        </label>
      <% end %>

      <div class="cost-summary">
        <div class="total-price">
          <span>(Subtotal) $</span> {if @sales_order.total_price,
            do: @sales_order.total_price.amount |> Decimal.to_float(),
            else: 0}
        </div>
        <div class="total-cost">
          <span>(Cost) $</span> {if @sales_order.total_cost,
            do: @sales_order.total_cost.amount |> Decimal.to_float(),
            else: 0}
        </div>
        <hr />
        <div class="total-subtotal">
          <span>(Net) $</span> {Money.sub!(
            @sales_order.total_price || Money.new(0, :USD),
            @sales_order.total_cost || Money.new(0, :USD)
          ).amount
          |> Decimal.to_float()}
        </div>
      </div>

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
      load: [
        :total_price,
        :total_cost,
        :address,
        sales_lines: [:total_price, :product, :active_price, :calculated_total_price, :total_cost],
        customer: [:addresses]
      ]
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
     |> assign(:total_price_changes, %{})
     |> assign(:total_cost_changes, %{})
     |> assign(:set_customer, %{text: nil, value: nil})
     |> assign(:addresses, sales_order.customer.addresses)
     |> assign(:default_customers, get_initial_customer_options(sales_order.customer_id))
     |> assign_form()}
  end

  defp page_title(:show), do: "Show Sales order"
  defp page_title(:edit), do: "Edit Sales order"

  defp record_total_price_change(
         socket,
         ["sales_order", "sales_lines", index, "total_price"]
       ) do
    changes = socket.assigns.total_price_changes
    changes = put_in(changes[index], true)

    socket
    |> assign(:total_price_changes, changes)
  end

  defp record_total_price_change(socket, _) do
    socket
  end

  defp record_total_cost_change(
         socket,
         ["sales_order", "sales_lines", index, "total_cost"]
       ) do
    changes = socket.assigns.total_cost_changes
    changes = put_in(changes[index], true)

    socket
    |> assign(:total_cost_changes, changes)
  end

  defp record_total_cost_change(socket, _) do
    socket
  end

  def handle_event(
        "save",
        %{"revert" => "revert-cost-" <> index, "sales_order" => params},
        socket
      ) do
    new_params = put_in(params, ["sales_lines", index, "unit_cost"], nil)

    form =
      AshPhoenix.Form.validate(socket.assigns.form, new_params)

    {:noreply,
     socket
     |> assign(:form, to_form(form))
     |> assign(:params, new_params)
     |> assign(:unsaved_changes, form.source.changed?)
     |> assign(:total_price_changes, Map.put(socket.assigns.total_price_changes, index, false))}
  end

  def handle_event(
        "save",
        %{"revert" => "revert-price-" <> index, "sales_order" => params},
        socket
      ) do
    new_params = put_in(params, ["sales_lines", index, "sales_price"], nil)

    form =
      AshPhoenix.Form.validate(socket.assigns.form, new_params)

    {:noreply,
     socket
     |> assign(:form, to_form(form))
     |> assign(:params, new_params)
     |> assign(:unsaved_changes, form.source.changed?)
     |> assign(:total_price_changes, Map.put(socket.assigns.total_price_changes, index, false))}
  end

  def handle_event(
        "save",
        %{"revert" => "revert-total-price-" <> index, "sales_order" => params},
        socket
      ) do
    new_params = put_in(params, ["sales_lines", index, "total_price"], nil)

    form =
      AshPhoenix.Form.validate(socket.assigns.form, new_params)

    {:noreply,
     socket
     |> assign(:form, to_form(form))
     |> assign(:params, new_params)
     |> assign(:unsaved_changes, form.source.changed?)
     |> assign(:total_price_changes, Map.put(socket.assigns.total_price_changes, index, false))}
  end

  def handle_event(
        "save",
        %{"revert" => "revert-total-cost-" <> index, "sales_order" => params},
        socket
      ) do
    new_params = put_in(params, ["sales_lines", index, "total_cost"], nil)

    form =
      AshPhoenix.Form.validate(socket.assigns.form, new_params)

    {:noreply,
     socket
     |> assign(:form, to_form(form))
     |> assign(:params, new_params)
     |> assign(:unsaved_changes, form.source.changed?)
     |> assign(:total_cost_changes, Map.put(socket.assigns.total_cost_changes, index, false))}
  end

  def erase_total_price_changes(sales_order_params, price_changes) do
    new_lines =
      for {id, line} <- sales_order_params["sales_lines"], into: %{} do
        if price_changes[id] != false do
          {id, line}
        else
          new_line = put_in(line["total_price"], nil)
          {id, new_line}
        end
      end

    put_in(sales_order_params["sales_lines"], new_lines)
  end

  def erase_total_cost_changes(sales_order_params, cost_changes) do
    new_lines =
      for {id, line} <- sales_order_params["sales_lines"], into: %{} do
        if cost_changes[id] != false do
          {id, line}
        else
          new_line = put_in(line["total_cost"], nil)
          {id, new_line}
        end
      end

    put_in(sales_order_params["sales_lines"], new_lines)
  end

  def process_modifications(sales_order_params, socket) do
    sales_order_params =
      erase_total_price_changes(sales_order_params, socket.assigns.total_price_changes)

    sales_order_params =
      erase_total_cost_changes(sales_order_params, socket.assigns.total_cost_changes)
  end

  @impl true
  def handle_event(
        "validate",
        %{"sales_order" => sales_order_params, "_target" => target} = params,
        socket
      ) do
    sales_order_params = process_modifications(sales_order_params, socket)

    socket =
      socket
      |> record_total_price_change(params["_target"])
      |> record_total_cost_change(params["_target"])

    output =
      (sales_order_params["sales_lines"] || [])
      |> Enum.map(fn {id, val} ->
        {id, val["product_id"]}
      end)
      |> Enum.find(fn {_id, val} -> val == "create" end)

    has_create =
      case output do
        {id, "create"} -> id
        _ -> nil
      end

    if sales_order_params["address_id"] == "create" and
         sales_order_params["customer_id"] not in [nil, "create"] and
         target != ["sales_order", "customer_id"] do
      {:noreply,
       socket
       |> Breadcrumbs.navigate_to(
         {"addresses", "new", sales_order_params["customer_id"]},
         {"sales_orders", socket.assigns.sales_order.id, sales_order_params,
          socket.assigns.sales_order.identifier}
       )}
    else
      if has_create do
        {:noreply,
         socket
         |> Breadcrumbs.navigate_to(
           {"products", "new", has_create},
           {"sales_orders", socket.assigns.sales_order.id, sales_order_params,
            socket.assigns.sales_order.identifier}
         )}
      else
        if sales_order_params["customer_id"] == "create" do
          sid = socket.assigns.sales_order.id

          {:noreply,
           socket
           |> Breadcrumbs.navigate_to(
             {"entities", "new", sid},
             {"sales_orders", socket.assigns.sales_order.id, sales_order_params,
              socket.assigns.sales_order.identifier}
           )}
        else
          set_customer =
            socket.assigns.default_customers
            |> Enum.find(fn c -> c.value == sales_order_params["customer_id"] end)
            |> case do
              nil -> %{text: nil, value: nil}
              c -> %{text: c.label, value: c.value}
            end

          # If address_id not in customer addresses we want to reset the sales_order_params["address_id"] to nil
          # Load the customer by sales_order_params["customer_id"]
          customer =
            Ash.get!(TheronsErp.People.Entity, sales_order_params["customer_id"],
              load: [:addresses]
            )

          form = AshPhoenix.Form.validate(socket.assigns.form, sales_order_params)
          drop = length(sales_order_params["_drop_sales_lines"] || [])

          {:noreply,
           assign(socket, form: form)
           |> assign(:unsaved_changes, form.source.changed? || drop > 0)
           |> assign(:set_customer, set_customer)
           |> assign(:addresses, customer.addresses)
           |> assign(:params, sales_order_params)
           |> assign(:drop_sales, drop)}
        end
      end
    end
  end

  def handle_event("save", %{"sales_order" => sales_order_params}, socket) do
    sales_order_params = process_modifications(sales_order_params, socket)

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
          |> push_navigate(
            to:
              ~p"/sales_orders/#{sales_order.id}?#{[breadcrumbs: Breadcrumbs.encode_breadcrumbs(socket.assigns.breadcrumbs)]}"
          )

        # |> push_patch(to: socket.assigns.patch)

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  def handle_event("set-ready", _, socket) do
    Ash.Changeset.for_update(socket.assigns.sales_order, :ready) |> Ash.update!()
    {:noreply, socket |> assign(:sales_order, load_by_id(socket.assigns.sales_order.id, socket))}
  end

  def handle_event("set-draft", _, socket) do
    Ash.Changeset.for_update(socket.assigns.sales_order, :revive) |> Ash.update!()
    {:noreply, socket |> assign(:sales_order, load_by_id(socket.assigns.sales_order.id, socket))}
  end

  defp is_active_price_persisted?(sales_line, index, total_price_changes) do
    if total_price_changes[to_string(index)] == false do
      false
    else
      case sales_line.source.data do
        # In case there's no data source (e.g., new line)
        nil ->
          false

        line_data ->
          line_data.total_price != nil
      end
    end
  end

  defp is_total_cost_persisted?(sales_line, index, total_cost_changes) do
    if total_cost_changes[to_string(index)] == false do
      false
    else
      case sales_line.source.data do
        # In case there's no data source (e.g., new line)
        nil ->
          false

        line_data ->
          line_data.total_cost != nil
      end
    end
  end

  defp active_price_for_sales_line(sales_line, index, total_price_changes) do
    data_total_price =
      case Phoenix.HTML.Form.input_value(sales_line, :total_price) do
        # In case there's no data source (e.g., new line)
        nil -> nil
        total_price -> total_price
      end

    if (data_total_price && is_active_price_persisted?(sales_line, index, total_price_changes)) ||
         total_price_changes[to_string(index)] do
      case data_total_price do
        %Money{} ->
          data_total_price.amount |> Decimal.to_string()

        _ ->
          data_total_price
      end
    else
      sales_price = Phoenix.HTML.Form.input_value(sales_line, :sales_price)
      quantity = Phoenix.HTML.Form.input_value(sales_line, :quantity)

      case {sales_price, quantity} do
        {nil, nil} ->
          ""

        {_, nil} ->
          ""

        {nil, _} ->
          ""

        {_, _} ->
          Ash.calculate!(TheronsErp.Sales.SalesLine, :calculated_total_price,
            refs: %{sales_price: sales_price, quantity: quantity}
          )
          |> Money.to_decimal()
          |> Decimal.to_string()
      end
    end
  end

  # TODO consider using Ash.calculate!/2
  defp total_cost_for_sales_line(sales_line, index, total_cost_changes) do
    data_total_cost =
      case Phoenix.HTML.Form.input_value(sales_line, :total_cost) do
        # In case there's no data source (e.g., new line)
        nil -> nil
        total_cost -> total_cost
      end

    if (data_total_cost && is_total_cost_persisted?(sales_line, index, total_cost_changes)) ||
         total_cost_changes[to_string(index)] do
      case data_total_cost do
        %Money{} ->
          data_total_cost.amount |> Decimal.to_string()

        _ ->
          data_total_cost
      end
    else
      unit_price = Phoenix.HTML.Form.input_value(sales_line, :unit_price)
      quantity = Phoenix.HTML.Form.input_value(sales_line, :quantity)

      case {unit_price, quantity} do
        {nil, nil} ->
          ""

        {_, nil} ->
          ""

        {nil, _} ->
          ""

        {_, _} ->
          Ash.calculate!(TheronsErp.Sales.SalesLine, :total_cost,
            refs: %{unit_price: unit_price, quantity: quantity}
          )
          |> Money.to_decimal()
          |> Decimal.to_string()
      end
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
        {nil, nil} ->
          form

        {_, nil} ->
          AshPhoenix.Form.validate(form, args)

        {nil, _} ->
          new_args =
            put_in(
              from_args,
              ["sales_lines", from_args["line_id"], "product_id"],
              from_args["product_id"]
            )

          update_live_forms(new_args)
          AshPhoenix.Form.validate(form, new_args)

        _ ->
          cond do
            from_args["line_id"] ->
              new_args =
                put_in(
                  Map.merge(args, from_args),
                  ["sales_lines", from_args["line_id"], "product_id"],
                  from_args["product_id"]
                )

              update_live_forms(new_args)
              AshPhoenix.Form.validate(form, new_args)

            from_args["customer_id"] ->
              new_args =
                Map.merge(args, from_args)

              update_live_forms(new_args)
              AshPhoenix.Form.validate(form, new_args)

            from_args["address_id"] ->
              new_args =
                Map.merge(args, from_args)

              update_live_forms(new_args)
              AshPhoenix.Form.validate(form, new_args)
          end
      end

    socket
    |> assign(form: to_form(form))
    |> assign(:unsaved_changes, form.changed?)
  end

  defp update_live_forms(new_args) do
    for {line_no, line} <- new_args["sales_lines"] do
      pid =
        line["product_id"]

      if pid not in [nil, ""] do
        opts = get_initial_product_options(pid)

        id =
          "sales_order[sales_lines][#{line_no}]_product_id_live_select_component"

        send_update(LiveSelect.Component,
          options: opts,
          id: id,
          value: pid
        )
      end
    end
  end

  defp parse_select_id!(id) do
    [_, number] =
      Regex.run(~r/sales_order\[sales_lines\]\[(\d+)\]_product_id_live_select_component/, id)

    number
  end

  def handle_event(
        "live_select_change",
        %{"text" => text, "id" => "sales_order[sales_lines]" <> _ = id},
        socket
      ) do
    opts =
      get_products("")
      |> prepare_matches(text)

    send_update(LiveSelect.Component, id: id, options: opts)

    {:noreply, socket}
  end

  def handle_event(
        "live_select_change",
        %{"text" => text, "id" => "sales_order_customer_id" <> _ = id},
        socket
      ) do
    opts =
      get_customers("")
      |> prepare_matches(text)

    send_update(LiveSelect.Component, id: id, options: opts)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "set-default-customers",
        %{
          "id" => id
        },
        socket
      ) do
    if cid = socket.assigns.from_args["customer_id"] do
      opts = get_initial_customer_options(cid)
      send_update(LiveSelect.Component, options: opts, id: id, value: cid)
    else
      text =
        socket.assigns.set_customer.text ||
          (socket.assigns.sales_order.customer && socket.assigns.sales_order.customer.name) || ""

      value = socket.assigns.set_customer.value || socket.assigns.sales_order.customer_id

      opts = prepare_matches(socket.assigns.default_customers, text)

      send_update(LiveSelect.Component, options: opts, id: id, value: value)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "set-default",
        %{"id" => id},
        socket
      ) do
    number = parse_select_id!(id)

    pid = socket.assigns.from_args["product_id"]

    if socket.assigns.from_args["product_id"] &&
         socket.assigns.from_args["line_id"] == to_string(number) do
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
        opts = get_initial_product_options(value)

        send_update(LiveSelect.Component,
          options: opts,
          id: id,
          value: value
        )
      else
        opts = get_initial_product_options(nil)

        send_update(LiveSelect.Component,
          options: opts,
          id: id,
          value: nil
        )
      end
    end

    {:noreply, socket}
  end

  defp get_address(form, addresses) do
    id = Phoenix.HTML.Form.input_value(form, :address_id)
    Enum.find(addresses, &(&1.id == id))
  end
end
