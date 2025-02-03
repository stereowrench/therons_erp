defmodule TheronsErp.Inventory do
  use Ash.Domain,
    otp_app: :therons_erp

  resources do
    resource TheronsErp.Inventory.ProductCategory do
      define :create_category, args: [:name], action: :create
    end
  end
end
