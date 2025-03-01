defmodule TheronsErp.Repo.Migrations.AddProductCategoriesFullText do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:product_categories) do
      add :full_name, :text
    end
  end

  def down do
    alter table(:product_categories) do
      remove :full_name
    end
  end
end
