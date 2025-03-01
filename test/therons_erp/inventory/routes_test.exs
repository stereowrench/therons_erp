defmodule TheronsErp.RoutesTest do
  use TheronsErp.DataCase
  import TheronsErp.Generator
  alias TheronsErp.Inventory.{Routes}

  test "creating route with no type" do
    out =
      Routes
      |> Ash.Changeset.for_create(:create, %{name: "Test Route"})
      |> Ash.create()

    assert {:error, _} = out
  end

  test "creating route with no name" do
    out =
      Routes
      |> Ash.Changeset.for_create(:create, %{type: :push})
      |> Ash.create()

    assert {:error, _} = out
  end

  test "creating routes" do
    location1 = generate(location())
    location2 = generate(location())

    out =
      Routes
      |> Ash.Changeset.for_create(:create, %{
        name: "Test Route",
        type: :push,
        routes: [%{from_location_id: location1.id, to_location_id: location2.id}]
      })
      |> Ash.create()

    assert {:ok, %Routes{} = r} = out
    r = Ash.load!(r, routes: [:from_location, :to_location])
    [route] = r.routes
    assert route.from_location.id == location1.id
    assert route.to_location.id == location2.id
  end
end
