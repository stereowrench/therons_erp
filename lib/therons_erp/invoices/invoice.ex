defmodule TheronsErp.Invoices.Invoice do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Invoices,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStateMachine]

  postgres do
    table "invoices"
    repo TheronsErp.Repo
  end

  state_machine do
    initial_states([:draft])
    default_initial_state(:draft)

    transitions do
      transition(:send, from: [:draft], to: [:sent])
    end
  end

  actions do
    defaults [:read, create: [], update: []]

    update :send do
      change transition_state(:sent)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :identifier, :integer do
      generated? true
    end

    timestamps()
  end

  relationships do
    belongs_to :customer, TheronsErp.People.Entity
  end
end
