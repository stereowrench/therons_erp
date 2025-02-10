defmodule TheronsErp.People.Entity do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.People,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "entities"
    repo TheronsErp.Repo
  end

  actions do
    defaults [:read]

    create :create do
      argument :addresses, {:array, :map}

      change manage_relationship(:addresses, type: :create)
    end

    update :update do
      require_atomic? false
      argument :addresses, {:array, :map}

      change manage_relationship(:addresses, type: :direct_control)
    end

    destroy :destroy do
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    has_many :addresses, TheronsErp.People.Address
  end
end
