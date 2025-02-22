defmodule TheronsErp.Inventory.Route do
  use Ash.Resource,
    data_layer: :embedded

  attributes do
    attribute :from_location, :string, public?: true
    attribute :to_location, :string, public?: true
  end
end
