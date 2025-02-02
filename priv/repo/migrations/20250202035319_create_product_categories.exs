defmodule TheronsErp.Repo.Migrations.CreateProductCategories do
  use Ecto.Migration

  def change do
    create table(:product_categories) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
