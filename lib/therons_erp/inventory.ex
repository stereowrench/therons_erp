defmodule TheronsErp.Inventory do
  use Ash.Domain,
    otp_app: :therons_erp

  resources do
    resource TheronsErp.Inventory.ProductCategory do
      define :create_category, args: [:name], action: :create
      define :change_parent, args: [:product_category_id], action: :update_parent
    end

    resource TheronsErp.Inventory.Product
  end
end
