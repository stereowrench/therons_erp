defmodule TheronsErp.Inventory.Product.Types do
  use Ash.Type.Enum, values: [:goods, :service]
end
