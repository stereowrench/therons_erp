defmodule TheronsErp.Scheduler.SchedulerAgent do
  use GenServer

  def start_link(opts \\ []) do
    Keyword.validate!(opts, [:location_id])
    location = Keyword.fetch!(opts, :location_id)
    GenServer.start_link(__MODULE__, %{location_id: location})
  end

  def add_peer(pid, {_location, _product, _pid} = peer) do
    GenServer.call(pid, {:add_peer, peer})
  end

  def set_product_inventory(pid, {_product, _amount} = inv) do
    GenServer.call(pid, {:set_product_inventory, inv})
  end

  def init(state) do
    state = Map.put(state, :peers, %{})
    state = Map.put(state, :inventory, %{})
    {:ok, state}
  end

  defp put_inv(product, amount, state) do
    inventory = Map.put(state.inventory, product, amount)
    {:ok, Map.put(state, :inventory, inventory)}
  end

  defp put_peer({location, product, pid}, state) do
    peers = Map.put(state.peers, {location, product}, pid)
    {:ok, Map.put(state, :peers, peers)}
  end

  def handle_call({:set_product_inventory, {product, amount}}, _from, state) do
    {:reply, :ok, put_inv(product, amount, state)}
  end

  def handle_call({:add_peer, {_location, _product, _pid} = peer}, _from, state) do
    {:reply, :ok, put_peer(peer, state)}
  end
end
