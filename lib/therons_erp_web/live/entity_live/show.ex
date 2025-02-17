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

    <div class="prose">
      <h2>Addresses</h2>
    </div>
    <%= for address <- @entity.addresses do %>
      <div>
        <label class="fieldsetlikelabel">Address</label>
        <div class="fieldsetlike">
          <div class="address">
            <%!-- Address 1 --%>
            <div class="address-line">
              <span>
                <%!-- Address label --%>
                <span class="text-xs">Address</span>
                {address.address}
              </span>
            </div>
            <%!-- Address 2 --%>
            <div class="address2-line">
              <span>
                <span class="text-xs">Address 2</span>
                {address.address2}
              </span>
            </div>
            <div class="address-city-state-zip">
              <%!-- City --%>
              <div class="city-line">
                <span class="text-xs">City</span>
                {address.city}
              </div>
              <%!-- State --%>
              <div class="state-line">
                <span class="text-xs">State</span>
                {address.state}
              </div>
              <%!-- Zip Code --%>
              <div class="zip-line">
                <span class="text-xs">Zip Code</span>
                {address.zip_code}
              </div>
            </div>
            <%!-- Phone number --%>
            <div class="phone-line">
              <span class="text-xs">Phone Number</span>
              {address.phone}
            </div>
          </div>
        </div>
      </div>
    <% end %>

    <.back navigate={~p"/people"}>Back to entities</.back>

    <.modal
      :if={@live_action == :edit}
      id="entity-modal"
      show
      on_cancel={
        JS.navigate(
          TheronsErpWeb.Breadcrumbs.get_previous_path(
            @breadcrumbs,
            {"people", @entity.id}
          )
        )
      }
    >
      <.live_component
        module={TheronsErpWeb.EntityLive.FormComponent}
        id={@entity.id}
        title={@page_title}
        action={@live_action}
        current_user={@current_user}
        entity={@entity}
        patch={~p"/people/#{@entity}"}
        breadcrumbs={@breadcrumbs}
      />
    </.modal>

    <.modal
      :if={@live_action == :new_address}
      id="entity-modal"
      show
      on_cancel={
        JS.navigate(
          TheronsErpWeb.Breadcrumbs.get_previous_path(
            @breadcrumbs,
            {"people", @entity.id}
          )
        )
      }
    >
      <.live_component
        module={TheronsErpWeb.EntityLive.NewAddressFormComponent}
        id={@entity.id}
        title={@page_title}
        action={@live_action}
        current_user={@current_user}
        entity={@entity}
        patch={~p"/people/#{@entity}"}
        breadcrumbs={@breadcrumbs}
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
       Ash.get!(TheronsErp.People.Entity, id,
         actor: socket.assigns.current_user,
         load: [:addresses]
       )
     )}
  end

  defp page_title(:show), do: "Show Entity"
  defp page_title(:edit), do: "Edit Entity"
  defp page_title(:new_address), do: "New Address"
end
