defmodule TheronsErp.Repo.Migrations.TotalPricesOnSalesOrders do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:sales_lines) do
      modify :product_id, :uuid, null: false
      modify :sales_order_id, :uuid, null: false
      add :total_price, :money_with_currency
    end
  end

  def down do
    alter table(:sales_lines) do
      remove :total_price
      modify :sales_order_id, :uuid, null: true
      modify :product_id, :uuid, null: true
    end
  end
end
