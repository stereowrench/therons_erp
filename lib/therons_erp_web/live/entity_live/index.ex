defmodule TheronsErpWeb.EntityLive.Index do
  use TheronsErpWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Entities
      <:actions>
        <.link patch={~p"/people/new"}>
          <.button>New Entity</.button>
        </.link>
      </:actions>
    </.header>

    <.table
      id="entities"
      rows={@streams.entities}
      row_click={fn {_id, entity} -> JS.navigate(~p"/people/#{entity}") end}
    >
      <:col :let={{_id, entity}} label="Name">{entity.name}</:col>

      <:action :let={{_id, entity}}>
        <div class="sr-only">
          <.link navigate={~p"/people/#{entity}"}>Show</.link>
        </div>

        <.link patch={~p"/people/#{entity}/edit"}>Edit</.link>
      </:action>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="entity-modal"
      show
      on_cancel={JS.patch(~p"/people")}
    >
      <.live_component
        module={TheronsErpWeb.EntityLive.FormComponent}
        id={(@entity && @entity.id) || :new}
        title={@page_title}
        current_user={@current_user}
        action={@live_action}
        entity={@entity}
        patch={~p"/people"}
        breadcrumbs={@breadcrumbs}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(
       :entities,
       Ash.read!(TheronsErp.People.Entity, actor: socket.assigns[:current_user])
     )
     |> assign_new(:current_user, fn -> nil end)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Entity")
    |> assign(:entity, Ash.get!(TheronsErp.People.Entity, id, actor: socket.assigns.current_user))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Entity")
    |> assign(:entity, nil)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Entities")
    |> assign(:entity, nil)
  end

  @impl true
  def handle_info({TheronsErpWeb.EntityLive.FormComponent, {:saved, entity}}, socket) do
    {:noreply, stream_insert(socket, :entities, entity)}
  end
end
