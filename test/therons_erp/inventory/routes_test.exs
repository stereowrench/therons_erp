defmodule TheronsErp.RoutesTest do
  use TheronsErp.DataCase

  alias TheronsErp.Inventory.{Route, Routes}

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
    out =
      Routes
      |> Ash.Changeset.for_create(:create, %{
        name: "Test Route",
        type: :push,
        routes: [%{from_location: "a", to_location: "b"}]
      })
      |> Ash.create()

    assert {:ok, %Routes{} = r} = out
    [route] = r.routes
    assert route.from_location == "a"
    assert route.to_location == "b"
  end
end
