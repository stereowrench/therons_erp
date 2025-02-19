defmodule TheronsErpWeb.EntityLive.NewAddressFormComponent do
  use TheronsErpWeb, :live_component
  alias TheronsErpWeb.Breadcrumbs

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        New address for {@entity.name}
      </.header>
      <.simple_form
        for={@form}
        id="address-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:address]} label="Address" required />
        <.input field={@form[:address2]} label="Address2" />
        <.input field={@form[:city]} label="City" required />
        <.input
          field={@form[:state]}
          type="select"
          label="State"
          options={TheronsErp.People.Address.state_options()}
        />
        <.input field={@form[:zip_code]} label="Zip code" required />
        <.input field={@form[:phone]} label="Phone" required />

        <:actions>
          <.button phx-disable-with="Saving...">Save Address</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign(:address, nil) |> assign_form()}
  end

  @impl true
  def handle_event("validate", %{"address" => address_params}, socket) do
    {:noreply,
     assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, address_params))}
  end

  def handle_event("save", %{"address" => address_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: address_params) do
      {:ok, address} ->
        notify_parent({:saved, address})

        socket =
          socket
          |> put_flash(:info, "Address #{socket.assigns.form.source.type}d successfully")
          |> Breadcrumbs.navigate_back({"people", address.entity_id}, %{
            address_id: address.id,
            customer_id: address.entity_id
          })

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{address: address, entity: entity}} = socket) do
    form =
      if address do
        AshPhoenix.Form.for_update(address, :update,
          as: "address",
          actor: socket.assigns.current_user
        )
      else
        AshPhoenix.Form.for_create(TheronsErp.People.Address, :create,
          as: "address",
          actor: socket.assigns.current_user,
          prepare_source: fn source ->
            source
            |> Ash.Changeset.change_attribute(:entity_id, entity.id)
          end
        )
      end

    assign(socket, form: to_form(form))
  end
end
