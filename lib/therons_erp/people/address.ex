defmodule TheronsErp.People.Address do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.People,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "addresses"
    repo TheronsErp.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :address, :string
    attribute :city, :string
    attribute :state, :string
    attribute :zip_code, :string
    timestamps()
  end

  relationships do
    belongs_to :entity, TheronsErp.People.Entity
  end
end
