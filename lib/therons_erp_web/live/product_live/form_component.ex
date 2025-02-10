defmodule TheronsErpWeb.ProductLive.FormComponent do
  use TheronsErpWeb, :live_component
  alias TheronsErpWeb.Breadcrumbs
  import TheronsErpWeb.Selects

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage product records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="product-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:sales_price]} type="text" label="Sales price" /><.input
          field={@form[:type]}
          type="text"
          label="Type"
        />
        <%!-- <.input
          field={@form[:category_id]}
          type="text"
          label="Category"
        /> --%>

        <.live_select
          field={@form[:category_id]}
          label="Category"
          phx-target={@myself}
          options={@initial_options}
          update_min_len={0}
          phx-focus="set-default"
        >
          <:option :let={opt}>
            <.highlight matches={opt.matches} string={opt.label} value={opt.value} />
          </:option>
        </.live_select>

        <:actions>
          <.button phx-disable-with="Saving...">Save Product</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("set-default", %{"id" => id}, socket) do
    send_update(LiveSelect.Component, options: socket.assigns.categories, id: id)

    {:noreply, socket}
  end

  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    matches =
      Seqfuzz.matches(socket.assigns.categories, text, & &1.label, filter: true, sort: true)

    opts =
      (matches
       |> Enum.map(fn {categories, c} ->
         %{value: categories.value, label: categories.label, matches: c.matches}
       end)
       |> Enum.take(5)) ++ additional_options()

    send_update(LiveSelect.Component, id: live_select_id, options: opts)
    {:noreply, socket}
  end

  @impl true
  def update(assigns, socket) do
    current_category_id = (assigns.product && assigns.product.category_id) || nil

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:categories, get_categories(current_category_id))
     |> assign(:initial_options, get_initial_options(current_category_id))
     |> assign_form()}
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    if product_params["category_id"] == "create" do
      # TODO add breadcrumbs
      pid = if socket.assigns.product, do: socket.assigns.product.id, else: nil

      {:noreply,
       socket
       |> Breadcrumbs.navigate_to(
         {"product_category", "new", pid},
         {"product", "new", product_params}
       )}
    else
      {:noreply,
       assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, product_params))}
    end
  end

  def handle_event("save", %{"product" => product_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: product_params) do
      {:ok, product} ->
        notify_parent({:saved, product |> Ash.load!(:category)})

        socket =
          socket
          |> put_flash(:info, "Product #{socket.assigns.form.source.type}d successfully")
          |> push_patch(to: socket.assigns.patch)

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{product: product, args: args, from_args: from_args}} = socket) do
    form =
      if product do
        AshPhoenix.Form.for_update(product, :update,
          as: "product",
          actor: socket.assigns.current_user
        )
      else
        AshPhoenix.Form.for_create(TheronsErp.Inventory.Product, :create,
          as: "product",
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

    assign(socket, form: to_form(form))
  end
end
