defmodule TheronsErp.SchedulingTest do
  use TheronsErp.DataCase
  import TheronsErp.Generator
  require Ash.Query
  alias TheronsErp.Scheduler

  test "noop does nothing" do
  end

  defp get_balance_of_ledger(location, product, type \\ :predicted, date \\ nil) do
    id = "inv.#{type}.#{location.id}.#{product.identifier}"

    TheronsErp.Inventory.Movement.get_acct_id(id)

    if date do
      TheronsErp.Ledger.Account
      |> Ash.get!(%{identifier: id},
        load: [balance_as_of: date]
      )
      |> Map.get(:balance_as_of)
    else
      TheronsErp.Ledger.Account
      |> Ash.get!(%{identifier: id},
        load: :balance_as_of
      )
      |> Map.get(:balance_as_of)
    end
  end

  test "upsert account" do
    TheronsErp.Ledger.Account
    |> Ash.Changeset.for_create(:open, %{identifier: "foo", currency: "XIT"})
    |> Ash.create!()

    TheronsErp.Ledger.Account
    |> Ash.Changeset.for_create(:open, %{identifier: "foo", currency: "XIT"})
    |> Ash.create!()
  end

  test "ledger accepts date" do
    acct =
      TheronsErp.Ledger.Account
      |> Ash.Changeset.for_create(:open, %{identifier: "foo", currency: "XIT"})
      |> Ash.create!()

    acct2 =
      TheronsErp.Ledger.Account
      |> Ash.Changeset.for_create(:open, %{identifier: "foo2", currency: "XIT"})
      |> Ash.create!()

    TheronsErp.Ledger.Transfer
    |> Ash.Changeset.for_create(:transfer, %{
      amount: Money.new(200, :XIT),
      to_account_id: acct.id,
      from_account_id: acct2.id,
      timestamp: DateTime.shift(MyDate.now!(), day: 2)
    })
    |> Ash.create!()

    assert Money.equal?(
             TheronsErp.Ledger.Account
             |> Ash.get!(acct.id,
               load: [balance_as_of: [timestamp: MyDate.now!()]]
             )
             |> Map.get(:balance_as_of),
             Money.new(0, :XIT)
           )

    assert Money.equal?(
             TheronsErp.Ledger.Account
             |> Ash.get!(acct.id,
               load: [balance_as_of: [timestamp: DateTime.shift(MyDate.now!(), day: 2)]]
             )
             |> Map.get(:balance_as_of),
             Money.new(200, :XIT)
           )
  end

  test "push route" do
    loc_a = generate(location())
    loc_b = generate(location())
    routes = [%{from_location_id: loc_a.id, to_location_id: loc_b.id}]
    route = generate(routes(routes: routes, type: :push))
    vendor = generate(vendor())
    po = generate(purchase_order(vendor_id: vendor.id, destination_location_id: loc_a.id))

    po_item =
      generate(purchase_order_item(purchase_order_id: po.id, quantity: 2))
      |> Ash.load!(:product)

    # Add route to product
    # Ash.Changeset.for_update(po_item.product, :update, %{route_id: route.id})
    # |> Ash.update!()
    product_routes = generate(product_routes(product_id: po_item.product.id, routes_id: route.id))

    Scheduler.schedule()

    assert Money.equal?(get_balance_of_ledger(loc_a, po_item.product), Money.new(0, :XIT))
    assert Money.equal?(get_balance_of_ledger(loc_b, po_item.product), Money.new(2, :XIT))
  end

  test "pull route" do
    loc_a = generate(location())
    loc_b = generate(location())
    loc_c = generate(location())

    routes = [
      %{from_location_id: loc_a.id, to_location_id: loc_b.id},
      %{from_location_id: loc_b.id, to_location_id: loc_c.id}
    ]

    route = generate(routes(routes: routes, type: :pull))
    vendor = generate(vendor())
    po = generate(purchase_order(vendor_id: vendor.id, destination_location_id: loc_a.id))

    po_item =
      generate(purchase_order_item(purchase_order_id: po.id, quantity: 2))
      |> Ash.load!(:product)

    product_routes = generate(product_routes(product_id: po_item.product.id, routes_id: route.id))

    # Create sales order
    so =
      generate(sales_order())
      |> Ash.Changeset.for_update(:ready, %{})
      |> Ash.update!()

    sales_line =
      generate(
        sales_line(
          quantity: 2,
          product_id: po_item.product.id,
          sales_order_id: so.id,
          pull_location_id: loc_c.id
        )
      )

    Scheduler.schedule()

    so_loc =
      TheronsErp.Inventory.Location
      |> Ash.get!(%{name: "sales_order.#{so.id}.#{sales_line.id}"})

    assert Money.equal?(get_balance_of_ledger(loc_a, po_item.product), Money.new(0, :XIT))
    assert Money.equal?(get_balance_of_ledger(loc_b, po_item.product), Money.new(0, :XIT))
    assert Money.equal?(get_balance_of_ledger(loc_c, po_item.product), Money.new(0, :XIT))
    assert Money.equal?(get_balance_of_ledger(so_loc, po_item.product), Money.new(2, :XIT))
  end

  test "existing stock" do
    loc_a = generate(location())
    loc_b = generate(location())
    loc_c = generate(location())
    product = generate(product())

    movement1 =
      TheronsErp.Inventory.Movement
      |> Ash.Changeset.for_create(:create, %{
        quantity: 2,
        from_location_id: loc_a.id,
        to_location_id: loc_b.id,
        product_id: product.id
      })
      |> Ash.create!()

    assert Money.equal?(get_balance_of_ledger(loc_a, product, :actual), Money.new(0, :XIT))
    assert Money.equal?(get_balance_of_ledger(loc_b, product, :actual), Money.new(0, :XIT))
    assert Money.equal?(get_balance_of_ledger(loc_a, product, :predicted), Money.new(-2, :XIT))
    assert Money.equal?(get_balance_of_ledger(loc_b, product, :predicted), Money.new(2, :XIT))

    TheronsErp.Inventory.Movement.actualize!(movement1)

    assert Money.equal?(get_balance_of_ledger(loc_a, product, :actual), Money.new(-2, :XIT))
    assert Money.equal?(get_balance_of_ledger(loc_b, product, :actual), Money.new(2, :XIT))
    assert Money.equal?(get_balance_of_ledger(loc_a, product, :predicted), Money.new(-2, :XIT))
    assert Money.equal?(get_balance_of_ledger(loc_b, product, :predicted), Money.new(2, :XIT))

    routes = [
      %{from_location_id: loc_a.id, to_location_id: loc_b.id},
      %{from_location_id: loc_b.id, to_location_id: loc_c.id}
    ]

    route = generate(routes(routes: routes, type: :pull))
    product_routes = generate(product_routes(product_id: product.id, routes_id: route.id))

    so =
      generate(sales_order())
      |> Ash.Changeset.for_update(:ready, %{})
      |> Ash.update!()

    sales_line =
      generate(
        sales_line(
          quantity: 2,
          product_id: product.id,
          sales_order_id: so.id,
          pull_location_id: loc_c.id
        )
      )

    Scheduler.schedule()

    so_loc =
      TheronsErp.Inventory.Location
      |> Ash.get!(%{name: "sales_order.#{so.id}.#{sales_line.id}"})

    movements =
      TheronsErp.Inventory.Movement
      |> Ash.Query.filter(state == :ready)
      |> Ash.read!()

    for movement <- movements do
      TheronsErp.Inventory.Movement.actualize!(movement)
    end

    assert Money.equal?(get_balance_of_ledger(loc_a, product), Money.new(-2, :XIT))
    assert Money.equal?(get_balance_of_ledger(loc_a, product, :actual), Money.new(-2, :XIT))
    assert Money.equal?(get_balance_of_ledger(loc_b, product), Money.new(0, :XIT))
    assert Money.equal?(get_balance_of_ledger(loc_b, product, :actual), Money.new(0, :XIT))
    assert Money.equal?(get_balance_of_ledger(loc_c, product), Money.new(0, :XIT))
    assert Money.equal?(get_balance_of_ledger(loc_c, product, :actual), Money.new(0, :XIT))
    assert Money.equal?(get_balance_of_ledger(so_loc, product), Money.new(2, :XIT))
    assert Money.equal?(get_balance_of_ledger(so_loc, product, :actual), Money.new(2, :XIT))
  end

  test "fallback to purchase order if demand drops below threshold" do
    product = generate(product())
    vendor = generate(vendor())

    replenishment =
      generate(
        replenishment(
          product_id: product.id,
          vendor_id: vendor.id,
          trigger_quantity: 10,
          quantity_multiple: 5
        )
      )

    loc_a = generate(location())
    loc_b = generate(location())
    loc_c = generate(location())

    routes = [
      %{from_location_id: loc_a.id, to_location_id: loc_b.id},
      %{from_location_id: loc_b.id, to_location_id: loc_c.id}
    ]

    route = generate(routes(routes: routes, type: :pull))
    product_routes = generate(product_routes(product_id: product.id, routes_id: route.id))

    so =
      generate(sales_order())
      |> Ash.Changeset.for_update(:ready, %{})
      |> Ash.update!()

    sales_line =
      generate(
        sales_line(
          quantity: 2,
          product_id: product.id,
          sales_order_id: so.id,
          pull_location_id: loc_c.id
        )
      )

    Scheduler.schedule()

    so_loc =
      TheronsErp.Inventory.Location
      |> Ash.get!(%{name: "sales_order.#{so.id}.#{sales_line.id}"})

    assert Money.equal?(get_balance_of_ledger(loc_a, product), Money.new(13, :XIT))
    assert Money.equal?(get_balance_of_ledger(loc_b, product), Money.new(0, :XIT))
    assert Money.equal?(get_balance_of_ledger(loc_c, product), Money.new(0, :XIT))
    assert Money.equal?(get_balance_of_ledger(so_loc, product), Money.new(2, :XIT))
  end

  test "lead time is respected" do
    product = generate(product())
    vendor = generate(vendor())

    replenishment =
      generate(
        replenishment(
          product_id: product.id,
          vendor_id: vendor.id,
          trigger_quantity: 10,
          quantity_multiple: 5,
          lead_time_days: 5
        )
      )

    loc_a = generate(location())
    loc_b = generate(location())
    loc_c = generate(location())

    routes = [
      %{from_location_id: loc_a.id, to_location_id: loc_b.id},
      %{from_location_id: loc_b.id, to_location_id: loc_c.id}
    ]

    route = generate(routes(routes: routes, type: :pull))
    product_routes = generate(product_routes(product_id: product.id, routes_id: route.id))

    so =
      generate(sales_order())
      |> Ash.Changeset.for_update(:ready, %{})
      |> Ash.update!()

    sales_line =
      generate(
        sales_line(
          quantity: 2,
          product_id: product.id,
          sales_order_id: so.id,
          pull_location_id: loc_c.id
        )
      )

    Scheduler.schedule()

    so_loc =
      TheronsErp.Inventory.Location
      |> Ash.get!(%{name: "sales_order.#{so.id}.#{sales_line.id}"})

    assert Money.equal?(get_balance_of_ledger(loc_a, product, :predicted), Money.new(13, :XIT))

    assert Money.equal?(
             get_balance_of_ledger(loc_a, product, :predicted, MyDate.today()),
             Money.new(0, :XIT)
           )

    assert Money.equal?(get_balance_of_ledger(loc_b, product, :predicted), Money.new(0, :XIT))

    assert Money.equal?(
             get_balance_of_ledger(loc_b, product, :predicted, MyDate.today()),
             Money.new(0, :XIT)
           )

    assert Money.equal?(get_balance_of_ledger(loc_c, product, :predicted), Money.new(0, :XIT))

    assert Money.equal?(
             get_balance_of_ledger(loc_c, product, :predicted, MyDate.today()),
             Money.new(0, :XIT)
           )

    assert Money.equal?(get_balance_of_ledger(so_loc, product, :predicted), Money.new(2, :XIT))

    assert Money.equal?(
             get_balance_of_ledger(so_loc, product, :predicted, MyDate.today()),
             Money.new(0, :XIT)
           )
  end

  test "errors generated for overdrawn accounts"

  test "argument allows error if sales order cannot be fulfilled"

  test "argument allows error if manufacturing order cannot be filled"

  test "forbid cycles"

  test "inventory timing"

  def generate_transactions_at_time(amount, time) do
    from_account =
      TheronsErp.Ledger.Account
      |> Ash.Changeset.for_create(:open, %{identifier: "foo", currency: "XIT"})
      |> Ash.create!()

    to_account =
      TheronsErp.Ledger.Account
      |> Ash.Changeset.for_create(:open, %{identifier: "bar", currency: "XIT"})
      |> Ash.create!()

    TheronsErp.Ledger.Transfer
    |> Ash.Changeset.for_create(:transfer, %{
      amount: amount,
      timestamp: time,
      from_account_id: from_account.id,
      to_account_id: to_account.id
    })
    |> Ash.create!()

    to_account.id
  end

  test "get_next_available_balance" do
    account_id = generate_transactions_at_time(Money.new(2, :XIT), Date.add(MyDate.today(), 2))

    assert DateTime.to_date(
             TheronsErp.Ledger.Balance.get_next_available(Money.new(:XIT, 2), account_id)
           ) ==
             Date.add(MyDate.today(), 2)

    assert TheronsErp.Ledger.Balance.get_next_available(Money.new(:XIT, 3), account_id) == nil
  end
end
