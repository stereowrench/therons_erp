defmodule TheronsErp.ResourceLedger.Account do
  defmodule FirstBalance do
    use Ash.Resource.Calculation

    @impl true
    def load(_query, _opts, _context) do
      [:later_balances]
    end

    @impl true
    def calculate(records, opts, %{arguments: %{separator: separator}}) do
      IO.inspect(records)
      records

      # first(
      #                 later_balances,
      #                 field: :timestamp,
      #                 sort: [desc: :timestamp],
      #                 query: [filter: expr(balance >= ^arg(:request))]
      # ) do
    end
  end

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: TheronsErp.ResourceLedger,
    extensions: [AshDoubleEntry.Account]

  account do
    transfer_resource TheronsErp.ResourceLedger.Transfer
    balance_resource TheronsErp.ResourceLedger.Balance
  end

  postgres do
    table "resource_ledger_accounts"
    repo TheronsErp.Repo
  end

  actions do
    defaults [:read]

    create :open do
      accept [:identifier, :currency]
    end

    read :lock_accounts do
      prepare {AshDoubleEntry.Location.Preparations.LockForUpdate, []}
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :identifier, :string do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    has_many :balances, TheronsErp.ResourceLedger.Balance do
      destination_attribute :account_id
    end

    has_many :later_balances, TheronsErp.ResourceLedger.Balance do
      source_attribute :id
      destination_attribute :account_id
      filter expr(transfer.id > parent(transfer.id))
    end
  end

  calculations do
    calculate :next_available, :utc_datetime, FirstBalance do
      # :utc_datetime,
      argument :request, :decimal, allow_nil?: false
    end

    calculate :balance_as_of_ulid, :decimal do
      calculation {AshDoubleEntry.Account.Calculations.BalanceAsOfUlid, resource: __MODULE__}

      argument :timestamp, AshDoubleEntry.ULID do
        allow_nil? false
        allow_expr? true
        default &DateTime.utc_now/0
      end
    end
  end
end
