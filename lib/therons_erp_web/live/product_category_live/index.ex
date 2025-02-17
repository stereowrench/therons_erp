defmodule TheronsErpWeb.ProductCategoryLive.Index do
  use TheronsErpWeb, :live_view
  alias TheronsErpWeb.Breadcrumbs

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Product categories
      <:actions>
        <.link patch={~p"/product_categories/new"}>
          <.button>New Product category</.button>
        </.link>
      </:actions>
    </.header>

    <.table
      id="product_categories"
      rows={@streams.product_categories}
      row_click={
        fn {_id, product_category} ->
          JS.navigate(
            Breadcrumbs.navigate_to_url(
              @breadcrumbs,
              {"product_categories", "edit", product_category.id},
              {"product_categories"}
            )
          )
        end
      }
    >
      <:col :let={{_id, product_category}} label="Name">{product_category.full_name}</:col>

      <:action :let={{_id, product_category}}>
        <div class="sr-only">
          <.link navigate={
            JS.navigate(
              Breadcrumbs.navigate_to_url(
                @breadcrumbs,
                {"product_categories", "edit", product_category.id},
                {"product_categories"}
              )
            )
          }>
            Show
          </.link>
        </div>
      </:action>

      <:action :let={{id, product_category}}>
        <.link
          phx-click={JS.push("delete", value: %{id: product_category.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="product_category-modal"
      show
      on_cancel={
        JS.navigate(
          TheronsErpWeb.Breadcrumbs.get_previous_path(
            @breadcrumbs,
            {"product_category", "new", (@product_category && @product_category.id) || nil}
          )
        )
      }
    >
      <.live_component
        module={TheronsErpWeb.ProductCategoryLive.FormComponent}
        id={(@product_category && @product_category.id) || :new}
        title={@page_title}
        current_user={@current_user}
        action={@live_action}
        product_category={@product_category}
        breadcrumbs={@breadcrumbs}
        patch={~p"/product_categories"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(
       :product_categories,
       Ash.read!(TheronsErp.Inventory.ProductCategory, actor: socket.assigns[:current_user])
     )
     |> assign_new(:current_user, fn -> nil end)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, params) do
    product_category = TheronsErp.Inventory.create_category_stub!()

    socket
    |> assign(:page_title, "New Product category")
    |> assign(:product_category, nil)
    |> Breadcrumbs.navigate_to(
      {"product_category", "new_stub", product_category.id, params},
      {"product_categories"}
    )
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Product categories")
    |> assign(:product_category, nil)
  end

  @impl true
  def handle_info(
        {TheronsErpWeb.ProductCategoryLive.FormComponent, {:saved, product_category}},
        socket
      ) do
    {:noreply, stream_insert(socket, :product_categories, product_category)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product_category =
      Ash.get!(TheronsErp.Inventory.ProductCategory, id, actor: socket.assigns.current_user)

    Ash.destroy!(product_category, actor: socket.assigns.current_user)

    {:noreply, stream_delete(socket, :product_categories, product_category)}
  end
end
