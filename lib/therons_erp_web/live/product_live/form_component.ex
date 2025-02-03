defmodule TheronsErpWeb.ProductLive.FormComponent do
  use TheronsErpWeb, :live_component

  alias TheronsErp.Inventory
  alias TheronsErpWeb.KeywordHighlighter

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage product records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="product-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.live_select
          field={@form[:category_id]}
          phx-target={@myself}
          options={@category_opts}
          label="Category"
          update_min_len={0}
          phx-focus="set-default"
        >
          <:option :let={opt}>
            <.highlight matches={opt.matches} string={opt.label} value={opt.value} />
          </:option>
        </.live_select>
        <.input
          field={@form[:tags]}
          type="select"
          multiple
          label="Tags"
          options={[{"Option 1", "option1"}, {"Option 2", "option2"}]}
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Product</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  defp generate_category_options() do
    categories = Inventory.list_product_categories()

    Enum.map(categories, fn cat ->
      %{label: cat.name, value: to_string(cat.id), matches: []}
    end)
  end

  defp add_new_category(opts, text \\ "") do
    if Enum.find(opts, fn opt -> opt.label == text end) == nil do
      opts ++ [%{label: "Create new", value: -1, matches: []}]
    else
      opts
    end
  end

  @impl true
  def update(%{product: product} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:category_opts, fn -> generate_category_options() end)
     |> assign_new(:form, fn ->
       to_form(Inventory.change_product(product))
     end)}
  end

  @impl true
  def handle_event("set-default", %{"id" => id}, socket) do
    send_update(LiveSelect.Component,
      options: add_new_category(socket.assigns.category_opts),
      id: id
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    cats = generate_category_options()
    matches = Seqfuzz.matches(cats, text, & &1.label, filter: true, sort: true)

    opts =
      Enum.map(matches, fn {map, c} ->
        %{label: map.name, value: map.value, matches: c.matches}
      end)
      |> Enum.take(4)

    # If text is not exactly a match add a create new options
    opts = add_new_category(opts, text)

    send_update(LiveSelect.Component, id: live_select_id, options: opts)
    {:noreply, socket}
  end

  # @impl true
  # def handle_event("change", %{"product" => product_params}, socket) do
  # end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    if product_params["category_id"] == "-1" do
      socket =
        if socket.assigns.id == :new do
          socket
          |> push_redirect(
            to: ~p"/product_categories/new/#{[product: socket.assigns.product.id]}"
          )
        else
          socket
          |> push_redirect(to: ~p"/products/#{socket.assigns.id}/newcategory")
        end

      {:noreply, socket}
    else
      changeset = Inventory.change_product(socket.assigns.product, product_params)
      {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  def handle_event("save", %{"product" => product_params}, socket) do
    save_product(socket, socket.assigns.action, product_params)
  end

  defp save_product(socket, :edit, product_params) do
    case Inventory.update_product(socket.assigns.product, product_params) do
      {:ok, product} ->
        notify_parent({:saved, product})

        {:noreply,
         socket
         |> put_flash(:info, "Product updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_product(socket, :new, product_params) do
    case Inventory.create_product(product_params) do
      {:ok, product} ->
        notify_parent({:saved, product})

        {:noreply,
         socket
         |> put_flash(:info, "Product created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  def highlight(assigns) do
    KeywordHighlighter.highlight(assigns.string, assigns.matches, assigns.value)
  end
end
