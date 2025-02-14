defmodule TheronsErp.Inventory.ProductTest do
  use ExUnit.Case

  test "can make a product" do
    TheronsErp.Inventory.Product
    |> Ash.Changeset.for_create(:create)
  end
end
