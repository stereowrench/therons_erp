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
        <.input field={@form[:name]} type="text" label="Name" />
        <.inputs_for :let={address} field={@form[:addresses]}>
          <fieldset class="border border-solid border-gray-300 p-3">
            <legend>
              Address {to_string(address.index)}
              <label>
                <input
                  type="checkbox"
                  name={"#{@form.name}[_drop_addresses][]"}
                  value={address.index}
                  class="hidden"
                />

                <.icon name="hero-x-mark" />
              </label>
            </legend>
            <.input field={address[:address]} type="text" label="Address" />
            <.input field={address[:address2]} type="text" label="Address2" />
            <.input field={address[:city]} type="text" label="City" />
            <.input
              field={address[:state]}
              type="select"
              label="State"
              options={[
                "AL",
                "AK",
                "AZ",
                "AR",
                "CA",
                "CO",
                "CT",
                "DE",
                "FL",
                "GA",
                "HI",
                "ID",
                "IL",
                "IN",
                "IA",
                "KS",
                "KY",
                "LA",
                "ME",
                "MD",
                "MA",
                "MI",
                "MN",
                "MS",
                "MO",
                "MT",
                "NE",
                "NV",
                "NH",
                "NJ",
                "NM",
                "NY",
                "NC",
                "ND",
                "OH",
                "OK",
                "OR",
                "PA",
                "RI",
                "SC",
                "SD",
                "TN",
                "TX",
                "UT",
                "VT",
                "VA",
                "WA",
                "WV",
                "WI",
                "WY"
              ]}
            />
            <.input field={address[:zip_code]} type="text" label="Zip Code" pattern="[0-9]{5}" />
          </fieldset>
        </.inputs_for>

        <label>
          <input type="checkbox" name={"#{@form.name}[_add_addresses]"} value="end" class="hidden" />
          <.icon name="hero-plus" />
        </label>

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
        IO.inspect(form)
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
