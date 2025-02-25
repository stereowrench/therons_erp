defmodule TheronsErp.SchedulingTest do
  use TheronsErp.DataCase
  import TheronsErp.Generator
  alias TheronsErp.Scheduler

  test "noop does nothing" do
  end

  defp get_balance_of_ledger(location, product) do
    TheronsErp.Ledger.Account
    |> Ash.get!(%{identifier: "inv.predicted.#{location.id}.#{product.identifier}"},
      load: :balance_as_of
    )
    |> Map.get(:balance_as_of)
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
    Ash.Changeset.for_update(po_item.product, :update, %{route_id: route.id})
    |> Ash.update!()

    Scheduler.schedule()

    assert Money.equal?(get_balance_of_ledger(loc_a, po_item.product), Money.new(0, :XIT))
    assert Money.equal?(get_balance_of_ledger(loc_b, po_item.product), Money.new(2, :XIT))
  end

  test "pull route" do
    loc_a = generate(location())
    loc_b = generate(location())

    routes = [%{from_location_id: loc_a.id, to_location_id: loc_b.id}]
    route = generate(routes(routes: routes, type: :pull))
    vendor = generate(vendor())
    po = generate(purchase_order(vendor_id: vendor.id, destination_location_id: loc_a.id))

    po_item =
      generate(purchase_order_item(purchase_order_id: po.id, quantity: 2))
      |> Ash.load!(:product)

    # Add route to product
    Ash.Changeset.for_update(po_item.product, :update, %{route_id: route.id})
    |> Ash.update!()

    # Create sales order
    so = generate(sales_order())

    sales_line =
      generate(sales_line(quantity: 2, product_id: po_item.product.id, sales_order_id: so.id))

    Scheduler.schedule()

    assert Money.equal?(get_balance_of_ledger(loc_a, po_item.product), Money.new(0, :XIT))
    assert Money.equal?(get_balance_of_ledger(loc_b, po_item.product), Money.new(2, :XIT))
  end

  test "forbid cycles"
end
