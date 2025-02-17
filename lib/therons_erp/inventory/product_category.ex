defmodule TheronsErp.Inventory.ProductCategory do
  alias TheronsErp.Inventory
  alias TheronsErp.Inventory.ProductCategory

  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Inventory,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource],
    primary_read_warning?: false

  require Ash.Query

  postgres do
    table "product_categories"
    repo TheronsErp.Repo
  end

  actions do
    defaults [:read]

    read :list do
      primary? true
      prepare build(sort: [id: :desc])
    end

    destroy :delete do
      primary? true
    end

    create :create do
      accept [:name, :product_category_id]

      change &perform_full_name_update/2
    end

    create :create_stub do
      accept []

      change fn changeset, _context ->
        changeset
        |> Ash.Changeset.change_attribute(:name, "New Category")
        |> Ash.Changeset.change_attribute(:full_name, "New Category")
      end
    end

    update :update_parent do
      accept [:product_category_id, :name]
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

      has_many :products, TheronsErp.Inventory.Product do
        destination_attribute :category_id
      end
    end

    def validate_no_cycles(_cs, _model, ids \\ [])

    def validate_no_cycles(changeset, nil, _ids) do
      changeset
    end

    def validate_no_cycles(changeset, model, ids) do
      id = model.id

      if id in ids do
        error =
          Ash.Error.Changes.InvalidRelationship.exception(
            relationship: :product_category,
            message: "Cannot create a cycle in the product category tree"
          )

        Ash.Changeset.add_error(changeset, error, :product_category_id)
      else
        ids = [id | ids]

        if model.product_category_id != nil do
          next_model = Ash.get!(ProductCategory, model.product_category_id)
          validate_no_cycles(changeset, next_model, ids)
        else
          changeset
        end
      end
    end

    def perform_full_name_update(changeset, _) do
      first_id = Ash.Changeset.get_attribute(changeset, :id)
      first_model = if first_id != nil, do: Ash.get!(ProductCategory, first_id), else: nil

      changeset
      |> validate_no_cycles(first_model)
      |> Ash.Changeset.before_action(fn changeset ->
        farg = Ash.Changeset.get_attribute(changeset, :product_category_id)

        if farg == nil do
          name = Ash.Changeset.get_attribute(changeset, :name)

          Ash.Changeset.force_change_attribute(
            changeset,
            :full_name,
            name
          )
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
        pcid =
          case Ash.Changeset.get_attribute(changeset, :product_category_id) do
            {:ok, foo} -> foo
            _ -> nil
          end

        pcid2 =
          case Ash.Changeset.fetch_argument(changeset, :product_category_id) do
            {:ok, foo} -> foo
            :error -> :error
            _ -> nil
          end

        alt =
          is_nil(pcid) and
            not is_nil(pcid2)

        if not is_nil(pcid) or alt do
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
