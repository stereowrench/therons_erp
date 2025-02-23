defmodule TheronsErp.Inventory.Location do
  use Ash.Resource,
    otp_app: :therons_erp,
    data_layer: AshPostgres.DataLayer,
    domain: TheronsErp.Inventory

  postgres do
    table "locations"
    repo TheronsErp.Repo
  end

  actions do
    read :list do
      primary? true
    end

    create :create do
      accept [:name]
    end

    create :update do
      accept [:name]
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string

    timestamps()
  end

  relationships do
    has_many :to_transfers, TheronsErp.Inventory.Movement do
      destination_attribute :to_location_id
    end

    has_many :from_transfers, TheronsErp.Inventory.Movement do
      destination_attribute :from_location_id
    end
  end
end
