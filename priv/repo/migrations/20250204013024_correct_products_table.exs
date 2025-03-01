defmodule TheronsErp.Repo.Migrations.CorrectProductsTable do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:products, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :name, :text, null: false
      add :sales_price, :money_with_currency
      add :type, :text, default: "goods"

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :category_id,
          references(:product_categories,
            column: :id,
            name: "products_category_id_fkey",
            type: :uuid,
            prefix: "public"
          )
    end

    alter table(:product_categories) do
      remove :category_id
      remove :type
      remove :sales_price
      modify :full_name, :text, null: false
    end
  end

  def down do
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

    drop constraint(:products, "products_category_id_fkey")

    drop table(:products)
  end
end
