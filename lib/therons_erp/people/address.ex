defmodule TheronsErp.People.Address do
  def state_options do
    [
      "AL",
      "AK",
      "AZ",
      "AR",
      "CA",
      "CO",
      "CT",
      "DE",
      "FL",
      "GA",
      "HI",
      "ID",
      "IL",
      "IN",
      "IA",
      "KS",
      "KY",
      "LA",
      "ME",
      "MD",
      "MA",
      "MI",
      "MN",
      "MS",
      "MO",
      "MT",
      "NE",
      "NV",
      "NH",
      "NJ",
      "NM",
      "NY",
      "NC",
      "ND",
      "OH",
      "OK",
      "OR",
      "PA",
      "RI",
      "SC",
      "SD",
      "TN",
      "TX",
      "UT",
      "VT",
      "VA",
      "WA",
      "WV",
      "WI",
      "WY"
    ]
  end

  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.People,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "addresses"
    repo TheronsErp.Repo
  end

  actions do
    defaults [:read]

    create :create do
      primary? true
      accept [:address, :address2, :city, :state, :zip_code, :phone, :entity_id]
    end

    update :update do
      primary? true
      accept [:address, :address2, :city, :state, :zip_code, :phone, :entity_id]
    end

    destroy :destroy do
      primary? true
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :address, :string
    attribute :address2, :string
    attribute :city, :string
    attribute :state, :string
    attribute :zip_code, :string
    attribute :phone, :string

    timestamps()
  end

  relationships do
    belongs_to :entity, TheronsErp.People.Entity
  end
end
