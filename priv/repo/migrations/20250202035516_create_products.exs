defmodule TheronsErp.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string
      add :tags, {:array, :string}
      add :category_id, references(:product_categories, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:products, [:category_id])
  end
end
