defmodule TheronsErpWeb.ProductCategoryLive.Show do
  use TheronsErpWeb, :live_view
  alias TheronsErpWeb.Breadcrumbs
  import TheronsErpWeb.Selects

  @impl true
  def render(assigns) do
    ~H"""
    <.simple_form for={@form} id="product-inline-form" phx-change="validate" phx-submit="save">
      <.header>
        {@product_category.full_name}

        <%= if @unsaved_changes do %>
          <.button phx-disable-with="Saving..." class="save-button">
            <.icon name="hero-check-circle" />
          </.button>
        <% end %>

        <:subtitle></:subtitle>

        <:actions>
          <%!-- <.link
            patch={~p"/product_categories/#{@product_category}/show/edit"}
            phx-click={JS.push_focus()}
          >
            <.button>Edit product_category</.button>
          </.link> --%>
        </:actions>
      </.header>

      <.input field={@form[:name]} label="Name" type="text" data-1p-ignore />

      <%= if @live_action != :edit do %>
        <div>
          <.live_select
            field={@form[:product_category_id]}
            label="Parent Category"
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
              <%= if Phoenix.HTML.Form.input_value(@form, :product_category_id) do %>
                <span class="link-to-inside-field">
                  <.link navigate={
                    TheronsErpWeb.Breadcrumbs.navigate_to_url(
                      @breadcrumbs,
                      {"product_category", Phoenix.HTML.Form.input_value(@form, :product_category_id),
                       get_category_name(
                         @categories,
                         Phoenix.HTML.Form.input_value(@form, :product_category_id)
                       )},
                      {"product_category", @product_category.id, @product_category.full_name}
                    )
                  }>
                    <.icon name="hero-arrow-right" />
                  </.link>
                </span>
              <% end %>
            </:inject_adjacent>
          </.live_select>
        </div>
      <% end %>

      <div class="prose">
        <h2>Products</h2>
      </div>
      <.table
        id="products"
        rows={@product_category.products}
        row_click={
          fn product ->
            JS.navigate(
              TheronsErpWeb.Breadcrumbs.navigate_to_url(
                @breadcrumbs,
                {"products", product.id, product.name},
                {"product_category", @product_category.id, @product_category.full_name}
              )
            )
          end
        }
      >
        <:col :let={product} label="name">{product.name}</:col>
      </.table>

      <.back navigate={~p"/product_categories"}>Back to product_categories</.back>
    </.simple_form>

    <.modal
      :if={@live_action == :edit}
      id="product_category-modal"
      show
      on_cancel={JS.patch(~p"/product_categories/#{@product_category}")}
    >
      <.live_component
        module={TheronsErpWeb.ProductCategoryLive.FormComponent}
        id={@product_category.id}
        title={@page_title}
        action={@live_action}
        current_user={@current_user}
        product_category={@product_category}
        breadcrumbs={@breadcrumbs}
        patch={~p"/product_categories/#{@product_category}"}
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
    category =
      Ash.get!(TheronsErp.Inventory.ProductCategory, id,
        actor: socket.assigns.current_user,
        load: [:products, :product_category]
      )

    current_category_id = category.product_category_id

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(
       :product_category,
       category
     )
     |> assign(:args, params["args"])
     |> assign(:from_args, params["from_args"])
     |> assign(:initial_categories, get_initial_options(current_category_id))
     |> assign(:categories, get_categories(current_category_id))
     |> assign(:set_category, %{text: nil, value: nil})
     |> assign_form()}
  end

  defp page_title(:show), do: "Show Product category"
  defp page_title(:edit), do: "Edit Product category"

  defp assign_form(
         %{assigns: %{product_category: product_category, args: args, from_args: from_args}} =
           socket
       ) do
    form =
      AshPhoenix.Form.for_update(product_category, :update_parent,
        as: "product_category",
        actor: socket.assigns.current_user
      )

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

  @impl true
  def handle_event("validate", %{"product_category" => category_params}, socket) do
    if category_params["category_id"] == "create" do
      cid = socket.assigns.product_category.id

      {:noreply,
       socket
       |> Breadcrumbs.navigate_to(
         {"product_category", "new_cat", cid},
         {"product_category", cid, category_params}
       )}
    else
      id = category_params["product_category_id"]

      set_category =
        socket.assigns.categories
        |> Enum.find(fn c -> c.value == id end)
        |> case do
          nil -> %{text: nil, value: nil}
          c -> %{text: c.label, value: c.value}
        end

      form = AshPhoenix.Form.validate(socket.assigns.form, category_params)

      {:noreply,
       socket
       |> assign(form: form)
       |> assign(:unsaved_changes, form.source.changed?)
       |> assign(:set_category, set_category)}
    end
  end

  @impl true
  def handle_event(
        "set-default",
        %{"id" => "product_category_product_category_id_live_select_component" = id},
        socket
      ) do
    if cid = socket.assigns.from_args["parent_category_id"] do
      opts = get_initial_options(cid)

      send_update(LiveSelect.Component,
        options: opts,
        id: id,
        value: cid
      )
    else
      text =
        socket.assigns.set_category.text ||
          (socket.assigns.product_category.product_category &&
             socket.assigns.product_category.product_category.name) || ""

      value =
        socket.assigns.set_category.value || socket.assigns.product_category.product_category_id

      opts = prepare_matches(socket.assigns.categories, text)

      send_update(LiveSelect.Component,
        options: opts,
        id: id,
        value: value
      )
    end

    {:noreply, socket}
  end

  def handle_event(
        "live_select_change",
        %{
          "text" => text,
          "id" => "product_category_product_category_id_live_select_component" = id
        },
        socket
      ) do
    opts = prepare_matches(socket.assigns.categories, text)

    send_update(LiveSelect.Component, id: id, options: opts)
    {:noreply, socket}
  end

  def handle_event("save", %{"product_category" => category_params}, socket) do
    try do
      case AshPhoenix.Form.submit(socket.assigns.form, params: category_params) do
        {:ok, category} ->
          socket =
            socket
            |> put_flash(:info, "Category #{socket.assigns.form.source.type}d successfully")
            |> assign(
              :product_category,
              category
            )
            |> assign(:initial_categories, get_initial_options(category.id))
            |> assign(:categories, get_categories(category.id))
            |> assign_form()

          {:noreply, socket}

        {:error, form} ->
          {:noreply, assign(socket, form: form)}
      end
    rescue
      e in Ash.Error.Invalid ->
        case e do
          %{errors: errors} ->
            y =
              Enum.find(errors, fn
                r = %Ash.Error.Changes.InvalidRelationship{} ->
                  r.message == "Cannot create a cycle in the product category tree"

                _ ->
                  false
              end)

            if y do
              {:noreply,
               socket |> put_flash(:error, "Cannot create a cycle in the product category tree")}
            else
              raise e
            end

          _ ->
            raise e
        end
    end
  end
end
