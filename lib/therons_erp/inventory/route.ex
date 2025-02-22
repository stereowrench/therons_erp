defmodule TheronsErp.Inventory.Route do
  use Ash.Resource,
      data_layer: :embedded

  attributes do
    attribute :type, :atom, constraints: [one_of: [:push, :pull]]
    attribute :from_location, :string
    attribute :to_location, :string
  end
end
