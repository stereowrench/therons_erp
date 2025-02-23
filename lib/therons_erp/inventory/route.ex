defmodule TheronsErp.Inventory.Route do
  use Ash.Resource,
    data_layer: :embedded

  relationships do
    belongs_to :from_location, TheronsErp.Inventory.Location do
      public? true
    end

    belongs_to :to_location, TheronsErp.Inventory.Location do
      public? true
    end
  end
end
