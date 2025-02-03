defmodule TheronsErp.InventoryTest do
  use TheronsErp.DataCase

  alias TheronsErp.Inventory.ProductCategory
  alias TheronsErp.Inventory

  describe "categories" do
    test "nested categories" do
      cat1 = Inventory.create_category!("Category 1", %{product_category_id: nil})
      cat2 = Inventory.create_category!("Category 2", %{product_category_id: cat1.id})
    end
  end
end
