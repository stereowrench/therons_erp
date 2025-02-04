defmodule TheronsErp.Repo.Migrations.AddProducts do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:product_categories) do
      modify :full_name, :text, null: true
      add :sales_price, :money_with_currency
      add :type, :text, default: "goods"

      add :category_id,
          references(:product_categories,
            column: :id,
            name: "product_categories_category_id_fkey",
            type: :uuid,
            prefix: "public"
          )
    end
  end

  def down do
    drop constraint(:product_categories, "product_categories_category_id_fkey")

    alter table(:product_categories) do
      remove :category_id
      remove :type
      remove :sales_price
      modify :full_name, :text, null: false
    end
  end
end
