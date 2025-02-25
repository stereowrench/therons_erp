defmodule TheronsErp.Scheduler.SchedulerAgent do
  alias TheronsErp.Scheduler.SchedulerAgent
  use GenServer

  def start_link(opts \\ []) do
    Keyword.validate!(opts, [:location_id])
    location = Keyword.fetch!(opts, :location_id)
    GenServer.start_link(__MODULE__, %{location_id: location})
  end

  def add_sales_order(pid, sales_order) do
    GenServer.call(pid, {:add_sales_order, sales_order})
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

  def propagate_pull_route(pid, quantity, product_id) do
    GenServer.call(pid, {:propagate_pull_route, quantity, product_id})
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
    state =
      Map.put(
        state,
        :location_name,
        Ash.get!(TheronsErp.Inventory.Location, state.location_id).name
      )

    state = Map.put(state, :peers, %{})
    state = Map.put(state, :to_peers, %{})
    state = Map.put(state, :inventory, %{})
    state = Map.put(state, :new_movements, [])
    state = Map.put(state, :stale_movements, %{})
    state = Map.put(state, :purchase_orders, [])
    state = Map.put(state, :sales_orders, [])
    {:ok, state}
  end

  defp put_inv(product, amount, state) do
    inventory = Map.put(state.inventory, product, amount)
    Map.put(state, :inventory, inventory)
  end

  defp increase_inv(from_inventory_id, product, amount, state) do
    inventory =
      if state.inventory[product.id] do
        put_in(state.inventory, [product.id], state.inventory[product.id] + amount)
      else
        put_in(state.inventory, [product.id], amount)
      end

    Map.put(state, :inventory, inventory)
  end

  defp put_peer({location, product, pid}, state) do
    peers = Map.put(state.peers, {location, product}, pid)
    Map.put(state, :peers, peers)
  end

  defp put_to_peer({location, product, pid}, state) do
    peers = Map.put(state.to_peers, {location, product}, pid)
    Map.put(state, :to_peers, peers)
  end

  defp get_to_peer_for_product(state, product_id) do
    Enum.find(state.to_peers, fn {{_, product_id_m}, _} ->
      product_id_m == product_id
    end)
  end

  defp get_from_peer_for_product(state, product_id) do
    Enum.find(state.peers, fn {{_, product_id_m}, _} ->
      product_id_m == product_id
    end)
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

  def handle_call({:propagate_push_route, quantity, product_id}, _from, state)
      when not is_nil(quantity) do
    # TODO modify a stale movement if possible.
    peer = get_to_peer_for_product(state, product_id)

    if peer do
      {{location_id, _product_id}, pid} = peer

      movement = %{
        quantity: quantity,
        product_id: product_id,
        from_inventory_id: state.inventory_id,
        to_inventory_id: location_id
      }

      propagate_push_route(pid, quantity, product_id)

      {:reply, :ok, add_movements(state, movement)}
    else
      {:reply, :ok, state}
    end
  end

  def handle_call({:propagate_pull_route, quantity, product_id}, _from, state) do
    peer = get_from_peer_for_product(state, product_id)

    if peer do
      {{location_id, _product_id}, pid} = peer

      movement = %{
        quantity: quantity,
        product_id: product_id,
        to_inventory_id: state.inventory_id,
        from_inventory_id: location_id
      }

      propagate_pull_route(pid, quantity, product_id)

      {:reply, :ok, add_movements(state, movement)}
    else
      {:reply, :ok, state}
    end
  end

  def handle_call({:add_purchase_order, purchase_order}, _from, state) do
    accts = generate_po_accts(purchase_order)

    movements =
      for item <- purchase_order.items do
        peer = get_to_peer_for_product(state, item.product_id)

        if peer do
          {{location_id, _product_id}, pid} = peer
          propagate_push_route(pid, item.quantity, item.product_id)

          [
            %{
              quantity: item.quantity,
              product_id: item.product_id,
              from_inventory_id: accts[item.id].id,
              to_inventory_id: state.location_id
            },
            %{
              quantity: item.quantity,
              product_id: item.product_id,
              from_inventory_id: state.location_id,
              to_inventory_id: location_id
            }
          ]
        else
          [
            %{
              quantity: item.quantity,
              product_id: item.product_id,
              from_inventory_id: accts[item.id].id,
              to_inventory_id: state.location_id
            }
          ]
        end
      end
      |> List.flatten()

    {:reply, :ok,
     state
     |> Map.put(:purchase_orders, [purchase_order | state.purchase_orders])
     |> add_movements(movements)}
  end

  def handle_call({:receive_products, {from_inventory_id, product, amount}}, _from, state) do
    {:reply, :ok, increase_inv(from_inventory_id, product, amount, state)}
  end

  def handle_call(:generate_accounts, _from, state) do
    for %{
          from_inventory_id: from_inventory_id,
          product_id: product_id,
          to_inventory_id: to_inventory_id
        } <- state.new_movements do
      product = TheronsErp.Inventory.Product |> Ash.get!(product_id)
      generate_accounts(from_inventory_id, product)
      generate_accounts(to_inventory_id, product)
    end

    {:reply, :ok, state}
  end

  def handle_call(:persist, _from, state) do
    # Generate movements for add movements
    changesets =
      for %{
            from_inventory_id: from_inventory_id,
            product_id: product_id,
            to_inventory_id: to_inventory_id,
            quantity: quantity
          } <- state.new_movements do
        # predicted

        {:insert,
         TheronsErp.Inventory.Movement
         |> Ash.Changeset.for_create(:create, %{
           from_location_id: from_inventory_id,
           to_location_id: to_inventory_id,
           product_id: product_id,
           quantity: Decimal.new(quantity)
         })}
      end

    {:reply, changesets, state}
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

  def handle_call({:add_sales_order, sales_order}, _from, state) do
    # Add sales order to the scheduler
    accts = generate_so_accts(sales_order)

    movements =
      for item <- sales_order.sales_lines do
        peer = get_from_peer_for_product(state, item.product_id)

        if peer do
          {{location_id, _product_id}, pid} = peer
          propagate_pull_route(pid, item.quantity, item.product_id)

          [
            %{
              quantity: item.quantity,
              product_id: item.product_id,
              from_inventory_id: state.location_id,
              to_inventory_id: accts[item.id].id
            },
            %{
              quantity: item.quantity,
              product_id: item.product_id,
              to_inventory_id: state.location_id,
              from_inventory_id: location_id
            }
          ]
        else
          [
            %{
              quantity: item.quantity,
              product_id: item.product_id,
              to_inventory_id: accts[item.id].id,
              from_inventory_id: state.location_id
            }
          ]
        end
      end
      |> List.flatten()

    {:reply, :ok,
     state
     |> Map.put(:sales_orders, [sales_order | state.sales_orders])
     |> add_movements(movements)}
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

  defp get_so_identifier(so, so_item) do
    "so.#{so.id}.#{so_item.id}"
  end

  defp generate_so_accts(so) do
    for item <- so.sales_lines, into: %{} do
      acct =
        TheronsErp.Ledger.Account
        |> Ash.Changeset.for_create(:open, %{
          currency: "XIT",
          identifier: get_so_identifier(so, item)
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

  defp add_movements(state, movements) when is_list(movements) do
    %{state | new_movements: movements ++ state.new_movements}
  end

  defp add_movements(state, movement) do
    add_movements(state, [movement])
  end
end
