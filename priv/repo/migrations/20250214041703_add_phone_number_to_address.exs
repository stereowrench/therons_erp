defmodule TheronsErp.Repo.Migrations.AddPhoneNumberToAddress do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:addresses) do
      add :phone, :text
    end
  end

  def down do
    alter table(:addresses) do
      remove :phone
    end
  end
end
