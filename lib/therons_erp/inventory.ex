defmodule TheronsErp.Inventory do
  use Ash.Domain,
    otp_app: :therons_erp

  resources do
    resource TheronsErp.Inventory.ProductCategory do
      define :create_category, args: [:name], action: :create
      define :change_parent, args: [:product_category_id], action: :update_parent
      define :get_categories, action: :list
    end

    resource TheronsErp.Inventory.Product do
      define :create_product, args: [:name, :sales_price], action: :create
      define :update_product, args: [:name, :sales_price], action: :update
    end
  end
end
