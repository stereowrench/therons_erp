defmodule TheronsErp.Ledger.Account do
  use Ash.Resource,
    domain: Elixir.TheronsErp.Ledger,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshDoubleEntry.Account]

  account do
    # configure the other resources it will interact with
    transfer_resource TheronsErp.Ledger.Transfer
    balance_resource TheronsErp.Ledger.Balance
  end

  account do
    transfer_resource TheronsErp.Ledger.Transfer
    balance_resource TheronsErp.Ledger.Balance
  end

  postgres do
    table "ledger_accounts"
    repo TheronsErp.Repo
  end

  actions do
    defaults [:read]

    create :open do
      upsert? true
      upsert_identity :unique_identifier
      accept [:identifier, :currency]
    end

    read :lock_accounts do
      # Used to lock accounts while doing ledger operations
      prepare {AshDoubleEntry.Account.Preparations.LockForUpdate, []}
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :identifier, :string do
      allow_nil? false
    end

    attribute :currency, :string do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    has_many :balances, TheronsErp.Ledger.Balance do
      destination_attribute :account_id
    end
  end

  calculations do
    calculate :balance_as_of_ulid, :money do
      calculation {AshDoubleEntry.Account.Calculations.BalanceAsOfUlid, resource: __MODULE__}

      argument :ulid, AshDoubleEntry.ULID do
        allow_nil? false
        allow_expr? true
      end
    end

    calculate :balance_as_of, :money do
      calculation {AshDoubleEntry.Account.Calculations.BalanceAsOf, resource: __MODULE__}

      argument :timestamp, :utc_datetime_usec do
        allow_nil? false
        allow_expr? true
        default &DateTime.utc_now/0
      end
    end
  end

  identities do
    identity :unique_identifier, [:identifier]
  end
end
