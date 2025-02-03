defmodule TheronsErp.Ledger.Transfer do
  use Ash.Resource,
    domain: Elixir.TheronsErp.Ledger,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshDoubleEntry.Transfer]

  transfer do
    account_resource TheronsErp.Ledger.Account
    balance_resource TheronsErp.Ledger.Balance
  end

  postgres do
    table "ledger_transfers"
    repo TheronsErp.Repo
  end

  actions do
    defaults [:read]

    create :transfer do
      accept [:amount, :timestamp, :from_account_id, :to_account_id]
    end
  end

  changes do
    change AshDoubleEntry.Transfer.Changes.VerifyTransfer do
      only_when_valid? true
      on [:create, :update, :destroy]
    end
  end

  attributes do
    attribute :id, AshDoubleEntry.ULID do
      primary_key? true
      allow_nil? false
      default &AshDoubleEntry.ULID.generate/0
    end

    attribute :amount, :money do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :from_account, TheronsErp.Ledger.Account do
      attribute_writable? true
    end

    belongs_to :to_account, TheronsErp.Ledger.Account do
      attribute_writable? true
    end

    has_many :balances, TheronsErp.Ledger.Balance
  end
end
