defmodule TheronsErpWeb.EntityLive.FormComponent do
  use TheronsErpWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage entity records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="entity-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:addresses]} type="select" multiple label="Addresses" options={[]} />

        <:actions>
          <.button phx-disable-with="Saving...">Save Entity</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_form()}
  end

  @impl true
  def handle_event("validate", %{"entity" => entity_params}, socket) do
    {:noreply, assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, entity_params))}
  end

  def handle_event("save", %{"entity" => entity_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: entity_params) do
      {:ok, entity} ->
        notify_parent({:saved, entity})

        socket =
          socket
          |> put_flash(:info, "Entity #{socket.assigns.form.source.type}d successfully")
          |> push_patch(to: socket.assigns.patch)

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{entity: entity}} = socket) do
    form =
      if entity do
        AshPhoenix.Form.for_update(entity, :update,
          as: "entity",
          actor: socket.assigns.current_user
        )
      else
        AshPhoenix.Form.for_create(TheronsErp.People.Entity, :create,
          as: "entity",
          actor: socket.assigns.current_user
        )
      end

    assign(socket, form: to_form(form))
  end
end
