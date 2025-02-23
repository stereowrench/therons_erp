defmodule TheronsErp.Inventory do
  use Ash.Domain, otp_app: :therons_erp, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource TheronsErp.Inventory.Routes
    resource TheronsErp.Inventory.Movement

    resource TheronsErp.Inventory.ProductCategory do
      define :create_category, args: [:name], action: :create
      define :change_parent, args: [:product_category_id], action: :update_parent
      define :get_categories, action: :list
      define :create_category_stub, action: :create_stub
    end

    resource TheronsErp.Inventory.Product do
      define :create_product, args: [:name, :sales_price], action: :create
      define :update_product, args: [:name, :sales_price], action: :update
      define :create_product_stub, action: :create_stub
      define :get_saleable_products, action: :list_saleable
      define :get_products, action: :list
    end
  end
end
