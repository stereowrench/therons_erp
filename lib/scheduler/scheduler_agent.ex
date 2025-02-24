defmodule TheronsErp.Scheduler.SchedulerAgent do
  alias TheronsErp.Scheduler.SchedulerAgent
  use GenServer

  def start_link(opts \\ []) do
    Keyword.validate!(opts, [:location_id])
    location = Keyword.fetch!(opts, :location_id)
    GenServer.start_link(__MODULE__, %{location_id: location})
  end

  def add_peer(pid, {_location, _product, _pid} = peer) do
    GenServer.call(pid, {:add_peer, peer})
  end

  def add_to_peer(pid, {_location, _product, _pid} = peer) do
    GenServer.call(pid, {:add_to_peer, peer})
  end

  def set_product_inventory(pid, {_product, _amount} = inv) do
    GenServer.call(pid, {:set_product_inventory, inv})
  end

  def receive_products(pid, from_inventory_id, product, amount) do
    GenServer.call(pid, {:receive_products, {from_inventory_id, product, amount}})
  end

  def generate_accounts(pid) do
    GenServer.call(pid, :generate_accounts)
  end

  def add_movement(pid, movement) do
    GenServer.call(pid, {:add_movement, movement})
  end

  def propagate_push_route(pid, quantity, product_id) do
    GenServer.call(pid, {:propagate_push_route, quantity, product_id})
  end

  def add_new_movement(pid, movement) do
    GenServer.call(pid, {:add_new_movement, movement})
  end

  def add_purchase_order(pid, purchase_order) do
    GenServer.call(pid, {:add_purchase_order, purchase_order})
  end

  def process(pid) do
    GenServer.call(pid, :process, 1_000)
  end

  def persist(pid) do
    GenServer.call(pid, :persist)
  end

  def init(state) do
    state = Map.put(state, :peers, %{})
    state = Map.put(state, :to_peers, %{})
    state = Map.put(state, :inventory, %{})
    state = Map.put(state, :new_movements, %{})
    state = Map.put(state, :stale_movements, %{})
    {:ok, state}
  end

  defp put_inv(product, amount, state) do
    inventory = Map.put(state.inventory, product, amount)
    {:ok, Map.put(state, :inventory, inventory)}
  end

  defp increase_inv(from_inventory_id, product, amount, state) do
    new_movements =
      if state.new_movements[product.id] do
        put_in(state.new_movements, product.id, [
          {amount, from_inventory_id, product} | state.new_movements[product.id]
        ])
      else
        put_in(state.new_movements, product.id, [{amount, from_inventory_id, product}])
      end

    {:ok, Map.put(state, :new_movements, new_movements)}
  end

  defp put_peer({location, product, pid}, state) do
    peers = Map.put(state.peers, {location, product}, pid)
    {:ok, Map.put(state, :peers, peers)}
  end

  defp put_to_peer({location, product, pid}, state) do
    peers = Map.put(state.to_peers, {location, product}, pid)
    {:ok, Map.put(state, :to_peers, peers)}
  end

  defp get_to_peer_for_product(state, product_id) do
    Enum.find(state.to_peers, fn {_, product}, _pid -> product.id == product_id end)
  end

  def handle_call({:set_product_inventory, {product, amount}}, _from, state) do
    {:reply, :ok, put_inv(product, amount, state)}
  end

  def handle_call({:add_peer, {_location, _product, _pid} = peer}, _from, state) do
    {:reply, :ok, put_peer(peer, state)}
  end

  def handle_call({:add_to_peer, {_location, _product, _pid} = peer}, _from, state) do
    {:reply, :ok, put_to_peer(peer, state)}
  end

  def handle_call({:add_movement, movement}, _from, state) do
    {:reply, :ok, Map.put(state, :stale_movements, [movement | state.stale_movements])}
  end

  def handle_call({:add_new_movement, movement}, _from, state) do
    # TODO modify a stale movement if possible.
    {:reply, :ok, Map.put(state, :new_movements, [movement | state.new_movements])}
  end

  def handle_call({:propagate_push_route, quantity, product_id}, _from, state) do
    # TODO modify a stale movement if possible.
    peer = get_to_peer_for_product(state, product_id)

    if peer do
      movement = %{
        quantity: quantity,
        product_id: product_id,
        from_inventory_id: state.inventory_id,
        to_inventory_id: get_to_peer_for_product(state, product_id)
      }

      {:reply, :ok, Map.put(state, :new_movements, [movement | state.new_movements])}
    else
      {:reply, :ok, state}
    end
  end

  def handle_call({:add_purchase_order, purchase_order}, _from, state) do
    accts = generate_po_accts(purchase_order)

    movements =
      for item <- purchase_order.items do
        propagate_push_route(self(), item.quantity, item.product_id)

        %{
          product_id: item.product_id,
          from_inventory_id: accts[item.id],
          to_inventory_id: state.inventory_id
        }
      end

    {:reply, :ok,
     state
     |> Map.put(:purchase_orders, [purchase_order | state.purchase_orders])
     |> Map.put(:new_movements, movements ++ state.new_movements)}
  end

  def handle_call({:receive_products, {from_inventory_id, product, amount}}, _from, state) do
    {:reply, :ok, increase_inv(from_inventory_id, product, amount, state)}
  end

  def handle_call(:generate_accounts, _from, state) do
    for {_product_id, {_amount, _from_inventory_id, product}} <- state.add_movements do
      generate_accounts(state.location_id, product)
    end

    {:reply, :ok, state}
  end

  def handle_call(:persist, _from, state) do
    # Generate movements for add movements
    for {product_id, {amount, from_inventory_id, product}} <- state.add_movements do
      # predicted

      TheronsErp.Inventory.Movement
      |> Ash.Changeset.for_create(:create, %{
        from_location_id: from_inventory_id,
        to_location_id: state.location_id,
        product_id: product_id,
        quantity: amount
      })
      |> Ash.create!()
    end

    {:reply, :ok, state}
  end

  def handle_call(:process, _from, state) do
    # Move purchase orders through push
    for po <- state.purchase_orders do
      for item <- po.items do
        pid = find_route_for_product(item.product_id, state)

        if pid do
          SchedulerAgent.receive_products(pid, state.location_id, item.product_id, item.quantity)
        end
      end
    end

    {:reply, :ok, state}
  end

  defp find_route_for_product(product_id, state) do
    state.to_peers[product_id]
  end

  defp get_po_identifier(po, po_item) do
    "po.#{po.id}.#{po_item.id}"
  end

  defp generate_po_accts(po) do
    for item <- po.items, into: %{} do
      acct =
        TheronsErp.Ledger.Account
        |> Ash.Changeset.for_create(:open, %{
          identifier: get_po_identifier(po, item),
          currency: "XIT"
        })
        |> Ash.create!()

      {item.id, acct}
    end
  end

  defp get_inv_identifier(type, location_id, product) do
    TheronsErp.Inventory.Movement.get_inv_identifier(type, location_id, product.identifier)
  end

  defp generate_accounts(location_id, product) do
    TheronsErp.Ledger.Account
    |> Ash.Changeset.for_create(:open, %{
      identifier: get_inv_identifier(:actual, location_id, product),
      currency: "XIT"
    })
    |> Ash.create!()

    TheronsErp.Ledger.Account
    |> Ash.Changeset.for_create(:open, %{
      identifier: get_inv_identifier(:predicted, location_id, product),
      currency: "XIT"
    })
    |> Ash.create!()

    TheronsErp.Ledger.Account
    |> Ash.Changeset.for_create(:open, %{
      identifier: get_inv_identifier(:eager, location_id, product),
      currency: "XIT"
    })
    |> Ash.create!()
  end
end
