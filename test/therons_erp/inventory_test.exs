defmodule TheronsErp.InventoryTest do
  use TheronsErp.DataCase

  alias TheronsErp.Inventory

  describe "product_categories" do
    alias TheronsErp.Inventory.ProductCategory

    import TheronsErp.InventoryFixtures

    @invalid_attrs %{name: nil}

    test "list_product_categories/0 returns all product_categories" do
      product_category = product_category_fixture()
      assert Inventory.list_product_categories() == [product_category]
    end

    test "get_product_category!/1 returns the product_category with given id" do
      product_category = product_category_fixture()
      assert Inventory.get_product_category!(product_category.id) == product_category
    end

    test "create_product_category/1 with valid data creates a product_category" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %ProductCategory{} = product_category} = Inventory.create_product_category(valid_attrs)
      assert product_category.name == "some name"
    end

    test "create_product_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Inventory.create_product_category(@invalid_attrs)
    end

    test "update_product_category/2 with valid data updates the product_category" do
      product_category = product_category_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %ProductCategory{} = product_category} = Inventory.update_product_category(product_category, update_attrs)
      assert product_category.name == "some updated name"
    end

    test "update_product_category/2 with invalid data returns error changeset" do
      product_category = product_category_fixture()
      assert {:error, %Ecto.Changeset{}} = Inventory.update_product_category(product_category, @invalid_attrs)
      assert product_category == Inventory.get_product_category!(product_category.id)
    end

    test "delete_product_category/1 deletes the product_category" do
      product_category = product_category_fixture()
      assert {:ok, %ProductCategory{}} = Inventory.delete_product_category(product_category)
      assert_raise Ecto.NoResultsError, fn -> Inventory.get_product_category!(product_category.id) end
    end

    test "change_product_category/1 returns a product_category changeset" do
      product_category = product_category_fixture()
      assert %Ecto.Changeset{} = Inventory.change_product_category(product_category)
    end
  end

  describe "products" do
    alias TheronsErp.Inventory.Product

    import TheronsErp.InventoryFixtures

    @invalid_attrs %{name: nil, tags: nil}

    test "list_products/0 returns all products" do
      product = product_fixture()
      assert Inventory.list_products() == [product]
    end

    test "get_product!/1 returns the product with given id" do
      product = product_fixture()
      assert Inventory.get_product!(product.id) == product
    end

    test "create_product/1 with valid data creates a product" do
      valid_attrs = %{name: "some name", tags: ["option1", "option2"]}

      assert {:ok, %Product{} = product} = Inventory.create_product(valid_attrs)
      assert product.name == "some name"
      assert product.tags == ["option1", "option2"]
    end

    test "create_product/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Inventory.create_product(@invalid_attrs)
    end

    test "update_product/2 with valid data updates the product" do
      product = product_fixture()
      update_attrs = %{name: "some updated name", tags: ["option1"]}

      assert {:ok, %Product{} = product} = Inventory.update_product(product, update_attrs)
      assert product.name == "some updated name"
      assert product.tags == ["option1"]
    end

    test "update_product/2 with invalid data returns error changeset" do
      product = product_fixture()
      assert {:error, %Ecto.Changeset{}} = Inventory.update_product(product, @invalid_attrs)
      assert product == Inventory.get_product!(product.id)
    end

    test "delete_product/1 deletes the product" do
      product = product_fixture()
      assert {:ok, %Product{}} = Inventory.delete_product(product)
      assert_raise Ecto.NoResultsError, fn -> Inventory.get_product!(product.id) end
    end

    test "change_product/1 returns a product changeset" do
      product = product_fixture()
      assert %Ecto.Changeset{} = Inventory.change_product(product)
    end
  end
end
