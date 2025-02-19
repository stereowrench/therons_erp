defmodule TheronsErp.ResourceLedger.Transfer do
  use Ash.Resource,
    domain: TheronsErp.ResourceLedger,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshDoubleEntry.Transfer]

  transfer do
    account_resource TheronsErp.ResourceLedger.Account
    balance_resource TheronsErp.ResourceLedger.Balance
  end

  postgres do
    table "resource_ledger_transfers"
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
    attribute :amount, :decimal do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :from_location, TheronsErp.ResourceLedger.Account do
      attribute_writable? true
    end

    belongs_to :to_location, TheronsErp.ResourceLedger.Account do
      attribute_writable? true
    end

    has_many :balances, TheronsErp.ResourceLedger.Balance
  end
end
