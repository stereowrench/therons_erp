defmodule TheronsErp.InventoryTest do
  use TheronsErp.DataCase

  alias TheronsErp.Inventory.ProductCategory
  alias TheronsErp.Inventory

  describe "categories" do
    test "nested categories" do
      cat1 = Inventory.create_category!("Category 1", %{product_category_id: nil})
      cat2 = Inventory.create_category!("Category 2", %{product_category_id: cat1.id})
      cat3 = Inventory.create_category!("Category 3", %{product_category_id: cat1.id})
      cat4 = Inventory.create_category!("Category 4", %{product_category_id: cat3.id})

      assert Ash.get!(ProductCategory, cat1.id).full_name == "Category 1"
      assert Ash.get!(ProductCategory, cat2.id).full_name == "Category 1 / Category 2"
      assert Ash.get!(ProductCategory, cat3.id).full_name == "Category 1 / Category 3"

      assert Ash.get!(ProductCategory, cat4.id).full_name ==
               "Category 1 / Category 3 / Category 4"

      Inventory.change_parent!(cat2.id, cat3.id)

      assert Ash.get!(ProductCategory, cat2.id).full_name ==
               "Category 1 / Category 3 / Category 2"

      Inventory.change_parent!(cat3.id, nil)

      assert Ash.get!(ProductCategory, cat2.id).full_name == "Category 3 / Category 2"
      assert Ash.get!(ProductCategory, cat3.id).full_name == "Category 3"
    end
  end
end
