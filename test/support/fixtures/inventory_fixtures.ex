defmodule TheronsErp.InventoryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TheronsErp.Inventory` context.
  """

  @doc """
  Generate a product_category.
  """
  def product_category_fixture(attrs \\ %{}) do
    {:ok, product_category} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> TheronsErp.Inventory.create_product_category()

    product_category
  end

  @doc """
  Generate a product.
  """
  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> Enum.into(%{
        name: "some name",
        tags: ["option1", "option2"]
      })
      |> TheronsErp.Inventory.create_product()

    product
  end
end
