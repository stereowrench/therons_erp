defmodule TheronsErpWeb.Selects do
  alias TheronsErp.Inventory

  def prepare_matches(items, text) do
    matches =
      Seqfuzz.matches(items, text, & &1.label, filter: true, sort: true)

    (matches
     |> Enum.map(fn {items, c} ->
       %{value: items.value, label: items.label, matches: c.matches}
     end)
     |> Enum.take(5)) ++ additional_options()
  end

  def get_categories(selected) do
    _get_list(Inventory.get_categories!(), selected, & &1.full_name)
  end

  def get_products(selected) do
    _get_list(Inventory.get_products!(), selected, & &1.name)
  end

  defp _get_list(items, selected, mapper) do
    list =
      items
      |> Enum.map(fn item ->
        %{
          value: to_string(item.id),
          label: mapper.(item),
          matches: []
        }
      end)

    found = Enum.find(list, &(&1.value == to_string(selected)))

    if found do
      [found | list]
    else
      list
    end
    |> Enum.uniq()
  end

  def additional_options do
    [
      %{
        value: :create,
        label: "Create New",
        matches: []
      }
    ]
  end

  def additional_product_options do
    [
      %{
        value: :create,
        label: "Create New",
        matches: []
      }
    ]
  end

  def get_initial_options(selected) do
    (get_categories(selected) |> Enum.uniq() |> Enum.take(4)) ++ additional_options()
  end

  def get_initial_product_options(selected) do
    (get_products(selected)
     |> Enum.uniq()
     |> Enum.take(4)) ++ additional_product_options()
  end

  def get_category_name(categories, id) do
    found =
      categories
      |> Enum.find(&(to_string(&1.value) == to_string(id)))

    found.label
  end

  def get_product_name(products, id) do
    found =
      products
      |> Enum.find(&(to_string(&1.value) == to_string(id)))

    found.label
  end
end
