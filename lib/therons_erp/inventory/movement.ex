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
      accept [:from_location, :to_location, :quantity, :manually_created]
    end

    update :update do
      accept [:from_location, :to_location, :quantity, :manually_created]
    end

    destroy :destroy do
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :from_location, :string
    attribute :to_location, :string

    attribute :quantity, :decimal

    attribute :manually_created, :boolean, default: false

    timestamps()
  end

  relationships do
    belongs_to :actual_transfer, TheronsErp.Ledger.Transfer, attribute_type: AshDoubleEntry.ULID

    belongs_to :predicted_transfer, TheronsErp.Ledger.Transfer,
      attribute_type: AshDoubleEntry.ULID

    belongs_to :eager_transfer, TheronsErp.Ledger.Transfer, attribute_type: AshDoubleEntry.ULID
  end
end
