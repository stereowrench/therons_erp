defmodule TheronsErp.Ledger.Balance do
  use Ash.Resource,
    domain: Elixir.TheronsErp.Ledger,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshDoubleEntry.Balance]

  require Ash.Query

  balance do
    transfer_resource TheronsErp.Ledger.Transfer
    account_resource TheronsErp.Ledger.Account
  end

  postgres do
    table "ledger_balances"
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
      argument :from_account_id, :uuid_v7, allow_nil?: false
      argument :to_account_id, :uuid_v7, allow_nil?: false
      argument :delta, :money, allow_nil?: false
      argument :transfer_id, AshDoubleEntry.ULID, allow_nil?: false

      change filter expr(
                      account_id in [^arg(:from_account_id), ^arg(:to_account_id)] and
                        transfer_id > ^arg(:transfer_id)
                    )

      change {AshDoubleEntry.Balance.Changes.AdjustBalance, can_add_money?: true}
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :balance, :money do
      constraints storage_type: :money_with_currency
    end
  end

  relationships do
    belongs_to :transfer, TheronsErp.Ledger.Transfer do
      attribute_type AshDoubleEntry.ULID
      allow_nil? false
      attribute_writable? true
    end

    belongs_to :account, TheronsErp.Ledger.Account do
      allow_nil? false
      attribute_writable? true
    end

    has_many :later_balances, __MODULE__ do
      source_attribute :account_id
      destination_attribute :account_id
      filter expr(transfer.id > parent(transfer.id))
    end
  end

  calculations do
    calculate :timestamp, :utc_datetime, expr(transfer.timestamp)

    calculate :next_available,
              :utc_datetime,
              expr(
                first(
                  later_balances,
                  field: :timestamp,
                  query: [sort: [timestamp: :desc], filter: expr(balance >= ^arg(:request))]
                )
              ) do
      argument :request, :money, allow_nil?: false
    end
  end

  identities do
    identity :unique_references, [:account_id, :transfer_id]
  end

  def get_next_available(requested_amount, account_id) do
    TheronsErp.Ledger.Balance
    |> Ash.Query.filter(account_id == ^account_id)
    |> Ash.Query.filter(balance < ^requested_amount)
    |> Ash.Query.load(:timestamp)
    |> Ash.Query.sort(timestamp: :desc)
    |> Ash.Query.load(next_available: [request: requested_amount])
    |> Ash.read_one!()
    |> case do
      nil ->
        TheronsErp.Ledger.Balance
        |> Ash.Query.filter(account_id == ^account_id)
        |> Ash.Query.filter(balance > ^requested_amount or balance == ^requested_amount)
        |> Ash.Query.load(:timestamp)
        |> Ash.Query.sort(timestamp: :desc)
        |> Ash.Query.load(:transfer)
        |> Ash.read_one!()
        |> Map.get(:transfer)
        |> Map.get(:timestamp)

      %{next_available: next_available} ->
        next_available
    end
  end
end
