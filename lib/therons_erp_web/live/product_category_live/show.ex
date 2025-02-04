defmodule TheronsErpWeb.ProductCategoryLive.Show do
  use TheronsErpWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      {@product_category.name}

      <:subtitle>{@product_category.id}</:subtitle>

      <:actions>
        <.link
          patch={~p"/product_categories/#{@product_category}/show/edit"}
          phx-click={JS.push_focus()}
        >
          <.button>Edit product_category</.button>
        </.link>
      </:actions>
    </.header>

    <.list>
      <:item title="Id">{@product_category.id}</:item>
    </.list>

    <.back navigate={~p"/product_categories"}>Back to product_categories</.back>

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
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(
       :product_category,
       Ash.get!(TheronsErp.Inventory.ProductCategory, id, actor: socket.assigns.current_user)
     )}
  end

  defp page_title(:show), do: "Show Product category"
  defp page_title(:edit), do: "Edit Product category"
end
