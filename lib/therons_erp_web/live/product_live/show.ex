defmodule TheronsErpWeb.ProductLive.Show do
  use TheronsErpWeb, :live_view
  alias TheronsErpWeb.Breadcrumbs
  alias TheronsErp.Inventory

  @impl true
  def render(assigns) do
    ~H"""
    <.simple_form for={@form} id="product-inline-form" phx-change="validate" phx-submit="save">
      <.header>
        {@product.name}
        <%= if @unsaved_changes do %>
          <.button phx-disable-with="Saving..." class="save-button">
            <.icon name="hero-check-circle" />
          </.button>
        <% end %>
        <:subtitle></:subtitle>

        <:actions>
          <.link patch={~p"/products/#{@product}/show/edit"} phx-click={JS.push_focus()}>
            <.button>Edit product</.button>
          </.link>
        </:actions>

        <%= if @live_action != :edit do %>
          <div>
            <.live_select
              field={@form[:category_id]}
              label="Category"
              inline={true}
              options={@initial_categories}
              update_min_len={0}
              phx-focus="set-default"
              container_class="inline-container"
              text_input_class="inline-text-input"
              dropdown_class="inline-dropdown"
            >
              <:option :let={opt}>
                <.highlight matches={opt.matches} string={opt.label} value={opt.value} />
              </:option>
              <:inject_adjacent>
                <span class="link-to-inside-field">
                  <.link navigate={~p"/"}>
                    <.icon name="hero-arrow-right" />
                  </.link>
                </span>
              </:inject_adjacent>
            </.live_select>
          </div>
        <% end %>
      </.header>
      <.list>
        <:item title="Id">{@product.id}</:item>
      </.list>

      <.back navigate={~p"/products"}>Back to products</.back>
    </.simple_form>
    <.modal
      :if={@live_action == :edit}
      id="product-modal"
      show
      on_cancel={JS.patch(~p"/products/#{@product}")}
    >
      <.live_component
        module={TheronsErpWeb.ProductLive.FormComponent}
        id={@product.id}
        title={@page_title}
        action={@live_action}
        current_user={@current_user}
        breadcrumbs={@breadcrumbs}
        product={@product}
        args={@args}
        from_args={@from_args}
        patch={~p"/products/#{@product}"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _, socket) do
    product =
      Ash.get!(TheronsErp.Inventory.Product, id,
        actor: socket.assigns.current_user,
        load: :category
      )

    current_category_id = product.category_id

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:initial_categories, get_initial_options(current_category_id))
     |> assign(:categories, get_categories(current_category_id))
     |> assign(:product, product)
     |> assign(:args, params["args"])
     |> assign(:from_args, params["from_args"])
     |> assign(:set_category, %{text: nil, value: nil})
     |> assign(:unsaved_changes, false)
     |> assign_form()}
  end

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

    initial_categories =
      if from_args["category_id"] do
        get_initial_options(from_args["category_id"])
      else
        socket.assigns.initial_categories
      end

    socket
    |> assign(form: to_form(form))
    |> assign(:unsaved_changes, form.changed?)
    |> assign(:initial_categories, initial_categories)
  end

  defp page_title(:show), do: "Show Product"
  defp page_title(:edit), do: "Edit Product"

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    if product_params["category_id"] == "create" do
      pid = if socket.assigns.product, do: socket.assigns.product.id, else: nil

      {:noreply,
       socket
       |> Breadcrumbs.navigate_to(
         {"product_category", "new", pid},
         {"products", "edit", pid, product_params}
       )}
    else
      id = product_params["category_id"]

      set_category =
        socket.assigns.categories
        |> Enum.find(fn c -> c.value == id end)
        |> case do
          nil -> %{text: nil, value: nil}
          c -> %{text: c.label, value: c.value}
        end

      form = AshPhoenix.Form.validate(socket.assigns.form, product_params)

      {:noreply,
       socket
       |> assign(form: form)
       |> assign(:unsaved_changes, form.source.changed?)
       |> assign(:set_category, set_category)}
    end
  end

  def handle_event("save", %{"product" => product_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: product_params) do
      {:ok, product} ->
        socket =
          socket
          |> put_flash(:info, "Product #{socket.assigns.form.source.type}d successfully")
          |> Breadcrumbs.navigate_back({"products", "edit", product.id})

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  def handle_event(
        "live_select_change",
        %{"text" => text, "id" => "product_category_id_live_select_component" = id},
        socket
      ) do
    opts = prepare_matches(socket.assigns.categories, text)

    send_update(LiveSelect.Component, id: id, options: opts)
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "set-default",
        %{"id" => "product_category_id_live_select_component" = id},
        socket
      ) do
    if cid = socket.assigns.from_args["category_id"] do
      # text = socket.assigns.product.category.full_name
      # value = socket.assigns.product.category_id
      opts = get_initial_options(cid)

      send_update(LiveSelect.Component,
        options: opts,
        id: id,
        value: cid
      )
    else
      text =
        socket.assigns.set_category.text ||
          (socket.assigns.product.category && socket.assigns.product.category.full_name) || ""

      value = socket.assigns.set_category.value || socket.assigns.product.category_id
      opts = prepare_matches(socket.assigns.categories, text)

      send_update(LiveSelect.Component,
        options: opts,
        id: id,
        value: value
      )
    end

    {:noreply, socket}
  end

  defp prepare_matches(categories, text) do
    matches =
      Seqfuzz.matches(categories, text, & &1.label, filter: true, sort: true)

    (matches
     |> Enum.map(fn {categories, c} ->
       %{value: categories.value, label: categories.label, matches: c.matches}
     end)
     |> Enum.take(5)) ++ additional_options()
  end

  def get_categories(selected) do
    list =
      Inventory.get_categories!()
      |> Enum.map(fn cat ->
        %{
          value: to_string(cat.id),
          label: cat.full_name,
          matches: []
        }
      end)

    found = Enum.find(list, &(&1.value == to_string(selected)))

    if found do
      [found | list]
    else
      list
    end
    |> Enum.uniq()
  end

  def additional_options do
    [
      %{
        value: :create,
        label: "Create New",
        matches: []
      }
    ]
  end

  def get_initial_options(selected) do
    (get_categories(selected) ++ additional_options()) |> Enum.uniq() |> Enum.take(5)
  end
end
