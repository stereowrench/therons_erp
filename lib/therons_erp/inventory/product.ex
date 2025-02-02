defmodule TheronsErp.Inventory.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string
    field :tags, {:array, :string}
    field :category_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :tags, :category_id])
    |> validate_required([:name, :category_id])
  end
end
