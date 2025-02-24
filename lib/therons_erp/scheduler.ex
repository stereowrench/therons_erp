defmodule TheronsErp.Scheduler do
  @moduledoc """
  The Scheduler module is responsible for scheduling POs, MOs,
  and movements based on route rules.

  # How it works

  The scheduler takes all of the BoMs and ensures there are no cycles. Then the
  scheduler creates processes for each location.

  """
  require Ash.Query
  alias TheronsErp.Scheduler.SchedulerAgent

  def schedule() do
    TheronsErp.Repo.transaction(fn ->
      # TODO ensure no cycles. For now just set a timeout.
      purchase_orders =
        TheronsErp.Purchasing.PurchaseOrder
        |> Ash.Query.filter(state == :created)
        |> Ash.read!(load: [:items])

      locations =
        TheronsErp.Inventory.Location
        |> Ash.read!()

      movements =
        TheronsErp.Inventory.Movement
        |> Ash.Query.filter(state == :ready)
        |> Ash.read!()

      routes =
        TheronsErp.Inventory.Routes
        |> Ash.read!()

      location_map =
        for location <- locations, into: %{} do
          {:ok, pid} = SchedulerAgent.start_link(location_id: location.id)
          {location.id, pid}
        end

      # Link agents by routes
      for route <- routes do
        for r <- route.routes do
          to = location_map[r.to_location_id]
          from = location_map[r.from_location_id]

          if route.type == :push do
            SchedulerAgent.add_to_peer(to, {r.from_location_id, r.product_id, from})
          else
            SchedulerAgent.add_peer(to, {r.from_location_id, r.product_id, from})
          end
        end
      end

      for movement <- movements do
        SchedulerAgent.add_movement(location_map[movement.to_location_id], movement)
      end

      for purchase_order <- purchase_orders do
        SchedulerAgent.add_purchase_order(
          location_map[purchase_order.location_id],
          purchase_order
        )
      end

      for {_loc, agent} <- location_map do
        SchedulerAgent.process(agent)
      end

      for {_loc, agent} <- location_map do
        SchedulerAgent.generate_accounts(agent)
      end

      for {_loc, agent} <- location_map do
        SchedulerAgent.persist(agent)
      end
    end)
  end
end
