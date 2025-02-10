defmodule TheronsErpWeb.EntityLive.Show do
  use TheronsErpWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Entity {@entity.name}
      <:subtitle></:subtitle>

      <:actions>
        <.link patch={~p"/people/#{@entity}/show/edit"} phx-click={JS.push_focus()}>
          <.button>Edit entity</.button>
        </.link>
      </:actions>
    </.header>

    <.list>
      <:item title="Id">{@entity.id}</:item>
    </.list>

    <.back navigate={~p"/people"}>Back to entities</.back>

    <.modal
      :if={@live_action == :edit}
      id="entity-modal"
      show
      on_cancel={JS.patch(~p"/people/#{@entity}")}
    >
      <.live_component
        module={TheronsErpWeb.EntityLive.FormComponent}
        id={@entity.id}
        title={@page_title}
        action={@live_action}
        current_user={@current_user}
        entity={@entity}
        patch={~p"/people/#{@entity}"}
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
       :entity,
       Ash.get!(TheronsErp.People.Entity, id, actor: socket.assigns.current_user)
     )}
  end

  defp page_title(:show), do: "Show Entity"
  defp page_title(:edit), do: "Edit Entity"
end
