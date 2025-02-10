defmodule TheronsErpWeb.Selects do
  alias TheronsErp.Inventory

  def prepare_matches(categories, text) do
    matches =
      Seqfuzz.matches(categories, text, & &1.label, filter: true, sort: true)

    (matches
     |> Enum.map(fn {categories, c} ->
       %{value: categories.value, label: categories.label, matches: c.matches}
     end)
     |> Enum.take(5)) ++ additional_options()
  end

  def get_categories(selected) do
    list =
      Inventory.get_categories!()
      |> Enum.map(fn cat ->
        %{
          value: to_string(cat.id),
          label: cat.full_name,
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

  def get_initial_options(selected) do
    (get_categories(selected) ++ additional_options()) |> Enum.uniq() |> Enum.take(5)
  end


  def get_category_name(categories, id) do
    found =
      categories
      |> Enum.find(&(to_string(&1.value) == to_string(id)))

    found.label
  end
end
