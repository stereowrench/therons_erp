defmodule TheronsErp.SchedulingTest do
  use TheronsErp.DataCase
  import TheronsErp.Generator
  alias TheronsErp.Scheduler

  test "noop does nothing" do
  end

  defp get_balance_of_ledger(location, product) do
    TheronsErp.Ledger.Account
    |> Ash.get!(%{identifier: "inv.#{location.id}.#{product.identifier}"}, load: :balance_as_of)
    |> Map.get(:balance_as_of)
  end

  test "push route" do
    loc_a = generate(location())
    loc_b = generate(location())
    routes = [%{from_location_id: loc_a.id, to_location_id: loc_b.id}]
    route = generate(routes(routes: routes, type: :push))
    vendor = generate(vendor())
    po = generate(purchase_order(vendor_id: vendor.id))

    po_item =
      generate(purchase_order_item(purchase_order_id: po.id, quantity: 2)) |> Ash.load!(:product)

    Scheduler.schedule()

    assert Money.equal?(get_balance_of_ledger(loc_a, po_item.product), Money.new(0, :XIT))
    assert Money.equal?(get_balance_of_ledger(loc_b, po_item.product), Money.new(2, :XIT))
  end
end
