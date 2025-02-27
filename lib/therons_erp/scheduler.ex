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
    # TheronsErp.Repo.transaction(fn ->
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

    location_map =
      for location <- locations, into: %{} do
        {:ok, pid} = SchedulerAgent.start_link(location_id: location.id)
        Ecto.Adapters.SQL.Sandbox.allow(TheronsErp.Repo, self(), pid)

        {location.id, pid}
      end

    # Link agents by routes. Products have one route whereas routes have many products.

    products =
      TheronsErp.Inventory.Product
      |> Ash.Query.for_read(:list)
      |> Ash.read!(load: [:routes])

    # Initialize each location with its actual product inventory

    for product <- products do
      for location <- locations do
        id =
          TheronsErp.Inventory.Movement.get_inv_identifier(
            :actual,
            location.id,
            product.identifier
          )

        TheronsErp.Inventory.Movement.get_acct_id(id)

        balance =
          TheronsErp.Ledger.Account
          |> Ash.get!(%{identifier: id},
            load: :balance_as_of
          )
          |> Map.get(:balance_as_of)

        SchedulerAgent.set_product_inventory(location_map[location.id], {product, balance})
      end

      routes = product.routes

      for route <- routes do
        if route do
          for r <- route.routes do
            to = location_map[r.to_location_id]
            from = location_map[r.from_location_id]

            if route.type == :push do
              SchedulerAgent.add_to_peer(from, {r.to_location_id, product.id, to})
            else
              SchedulerAgent.add_peer(to, {r.from_location_id, product.id, from})
            end
          end
        end
      end
    end

    for movement <- movements do
      SchedulerAgent.add_movement(location_map[movement.to_location_id], movement)
    end

    for purchase_order <- purchase_orders do
      SchedulerAgent.add_purchase_order(
        location_map[purchase_order.destination_location_id],
        purchase_order
      )
    end

    for {_loc, agent} <- location_map do
      SchedulerAgent.process(agent)
    end

    sales_orders =
      TheronsErp.Sales.SalesOrder
      |> Ash.Query.filter(state in [:ready, :invoiced])
      |> Ash.read!(load: [sales_lines: [:pull_location, product: [:routes]]])

    for sales_order <- sales_orders do
      for sales_line <- sales_order.sales_lines do
        SchedulerAgent.add_sales_line(location_map[sales_line.pull_location_id], sales_line)
      end
    end

    for {_loc, agent} <- location_map do
      SchedulerAgent.generate_accounts(agent)
    end

    change_list =
      for {_loc, agent} <- location_map do
        SchedulerAgent.persist(agent)
      end
      |> List.flatten()

    TheronsErp.Repo.transaction(fn ->
      for change <- change_list do
        case change do
          {:update, changeset} ->
            Ash.update!(changeset)

          {:insert, changeset} ->
            from = Ash.Changeset.get_attribute(changeset, :from_location_id)
            to = Ash.Changeset.get_attribute(changeset, :to_location_id)
            quantity = Ash.Changeset.get_attribute(changeset, :quantity)
            Ash.create!(changeset)
        end
      end
    end)
  end
end
