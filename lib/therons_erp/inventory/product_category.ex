defmodule TheronsErp.Inventory.ProductCategory do
  alias TheronsErp.Inventory
  alias TheronsErp.Inventory.ProductCategory

  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Inventory,
    data_layer: AshPostgres.DataLayer

  require Ash.Query

  postgres do
    table "product_categories"
    repo TheronsErp.Repo
  end

  actions do
    defaults [:read]

    create :create do
      accept [:name, :product_category_id]

      change &perform_full_name_update/2
    end

    update :update_parent do
      accept [:product_category_id]
      require_atomic? false

      change &perform_full_name_update/2
    end

    attributes do
      uuid_primary_key :id

      attribute :name, :string do
        allow_nil? false
      end

      attribute :product_category_id, :uuid

      attribute :full_name, :string do
        allow_nil? false
      end

      timestamps()
    end

    relationships do
      belongs_to :product_category, TheronsErp.Inventory.ProductCategory

      has_many :subcategories, TheronsErp.Inventory.ProductCategory do
        destination_attribute :product_category_id
      end
    end

    def perform_full_name_update(changeset, _) do
      # TODO avoid infinte loops
      changeset
      |> Ash.Changeset.before_action(fn changeset ->
        farg = Ash.Changeset.get_attribute(changeset, :product_category_id)

        if farg == nil do
          name = Ash.Changeset.get_attribute(changeset, :name)

          Ash.Changeset.force_change_attribute(
            changeset,
            :full_name,
            name
          )

          # |> IO.inspect()
        else
          [parent] =
            ProductCategory
            |> Ash.Query.filter(id == ^farg)
            |> Ash.read!()

          name = Ash.Changeset.get_attribute(changeset, :name)

          Ash.Changeset.force_change_attribute(
            changeset,
            :full_name,
            parent.full_name <> " / " <> name
          )
        end
      end)
      |> Ash.Changeset.after_action(fn changeset, result ->
        # if Ash.Changeset.get_attribute(changeset, :product_category_id) != nil or (Ash.Changeset.fetch_argument(changeset, :product_category_id) == nil and ) do
        IO.inspect(changeset)

        alt =
          Ash.Changeset.get_attribute(changeset, :product_category_id) == nil and
            Ash.Changeset.fetch_argument(changeset, :product_category_id) != nil

        if Ash.Changeset.get_attribute(changeset, :product_category_id) != nil or alt do
          id = Ash.Changeset.get_attribute(changeset, :id)

          unless id == nil do
            subcats =
              ProductCategory
              |> Ash.Query.filter(product_category_id == ^id)
              |> Ash.read!()

            for cat <- subcats do
              Inventory.change_parent!(cat.id, changeset.data.id)
            end
          end
        end

        {:ok, result}
      end)
    end
  end
end
