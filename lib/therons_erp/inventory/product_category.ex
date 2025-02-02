defmodule TheronsErp.Inventory.ProductCategory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "product_categories" do
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product_category, attrs) do
    product_category
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
