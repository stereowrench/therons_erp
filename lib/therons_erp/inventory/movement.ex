defmodule TheronsErp.Inventory.Movement do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Inventory,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "movements"
    repo TheronsErp.Repo
  end

  actions do
    read :read do
    end

    create :create do
      accept [
        :from_location_id,
        :to_location_id,
        :quantity,
        :manually_created,
        :product_id,
        :actual_transfer_id,
        :predicted_transfer_id,
        :eager_transfer_id
      ]
    end

    update :update do
      accept [
        :from_location_id,
        :to_location_id,
        :quantity,
        :manually_created,
        :product_id,
        :actual_transfer_id,
        :predicted_transfer_id,
        :eager_transfer_id
      ]
    end

    destroy :destroy do
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :quantity, :decimal

    attribute :manually_created, :boolean, default: false

    timestamps()
  end

  relationships do
    belongs_to :product, TheronsErp.Inventory.Product

    belongs_to :actual_transfer, TheronsErp.Ledger.Transfer, attribute_type: AshDoubleEntry.ULID

    belongs_to :predicted_transfer, TheronsErp.Ledger.Transfer,
      attribute_type: AshDoubleEntry.ULID

    belongs_to :eager_transfer, TheronsErp.Ledger.Transfer, attribute_type: AshDoubleEntry.ULID

    belongs_to :from_location, TheronsErp.Inventory.Location
    belongs_to :to_location, TheronsErp.Inventory.Location
  end
end
