defmodule TheronsErp.ResourceLedger.Balance do
  use Ash.Resource,
    domain: TheronsErp.ResourceLedger,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshDoubleEntry.Balance]

  balance do
    transfer_resource TheronsErp.ResourceLedger.Transfer
    account_resource TheronsErp.ResourceLedger.Account
  end

  postgres do
    table "resource_ledger_balances"
    repo TheronsErp.Repo
  end

  actions do
    defaults [:read]

    create :upsert_balance do
      accept [:balance, :account_id, :transfer_id]
      upsert? true
      upsert_identity :unique_references
    end

    update :adjust_balance do
      argument :account_id, :uuid_v7, allow_nil?: false
      argument :to_account_id, :uuid_v7, allow_nil?: false
      argument :delta, :decimal, allow_nil?: false
      argument :transfer_id, AshDoubleEntry.ULID, allow_nil?: false

      change filter expr(
                      account_id in [^arg(:account_id), ^arg(:to_account_id)] and
                        transfer_id > ^arg(:transfer_id)
                    )

      change {AshDoubleEntry.Balance.Changes.AdjustBalance, can_add_money?: true}
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :balance, :decimal
  end

  relationships do
    belongs_to :transfer, TheronsErp.ResourceLedger.Transfer do
      attribute_type AshDoubleEntry.ULID
      allow_nil? false
      attribute_writable? true
    end

    belongs_to :account, TheronsErp.ResourceLedger.Account do
      allow_nil? false
      attribute_writable? true
    end
  end

  identities do
    identity :unique_references, [:account_id, :transfer_id]
  end
end
