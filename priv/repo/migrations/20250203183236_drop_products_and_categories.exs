defmodule TheronsErp.Repo.Migrations.DropProductsAndCategories do
  use Ecto.Migration

  def change do
    drop table(:products)
    drop table(:product_categories)
  end
end
