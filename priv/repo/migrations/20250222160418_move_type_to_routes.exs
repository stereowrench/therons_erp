defmodule TheronsErp.Repo.Migrations.MoveTypeToRoutes do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:routes) do
      add :name, :text, null: false
      add :type, :text
    end
  end

  def down do
    alter table(:routes) do
      remove :type
      remove :name
    end
  end
end
