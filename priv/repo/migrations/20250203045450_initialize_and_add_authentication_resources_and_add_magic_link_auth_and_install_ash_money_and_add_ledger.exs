defmodule TheronsErp.Repo.Migrations.InitializeAndAddAuthenticationResourcesAndAddMagicLinkAuthAndInstallAshMoneyAndAddLedger do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:users, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :email, :citext, null: false
    end

    create unique_index(:users, [:email], name: "users_unique_email_index")

    create table(:tokens, primary_key: false) do
      add :created_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :jti, :text, null: false, primary_key: true
      add :subject, :text, null: false
      add :expires_at, :utc_datetime, null: false
      add :purpose, :text, null: false
      add :extra_data, :map

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
    end

    create table(:ledger_transfers, primary_key: false) do
      add :id, :binary, null: false, primary_key: true
      add :amount, :money_with_currency, null: false

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :timestamp, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :from_account_id, :uuid
      add :to_account_id, :uuid
    end

    create table(:ledger_balances, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("uuid_generate_v7()"), primary_key: true
      add :balance, :money_with_currency

      add :transfer_id,
          references(:ledger_transfers,
            column: :id,
            name: "ledger_balances_transfer_id_fkey",
            type: :binary,
            prefix: "public"
          ),
          null: false

      add :account_id, :uuid, null: false
    end

    create table(:ledger_accounts, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("uuid_generate_v7()"), primary_key: true
    end

    alter table(:ledger_transfers) do
      modify :from_account_id,
             references(:ledger_accounts,
               column: :id,
               name: "ledger_transfers_from_account_id_fkey",
               type: :uuid,
               prefix: "public"
             )

      modify :to_account_id,
             references(:ledger_accounts,
               column: :id,
               name: "ledger_transfers_to_account_id_fkey",
               type: :uuid,
               prefix: "public"
             )
    end

    alter table(:ledger_balances) do
      modify :account_id,
             references(:ledger_accounts,
               column: :id,
               name: "ledger_balances_account_id_fkey",
               type: :uuid,
               prefix: "public"
             )
    end

    create unique_index(:ledger_balances, [:account_id, :transfer_id],
             name: "ledger_balances_unique_references_index"
           )

    alter table(:ledger_accounts) do
      add :identifier, :text, null: false
      add :currency, :text, null: false

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
    end

    create unique_index(:ledger_accounts, [:identifier],
             name: "ledger_accounts_unique_identifier_index"
           )
  end

  def down do
    drop_if_exists unique_index(:ledger_accounts, [:identifier],
                     name: "ledger_accounts_unique_identifier_index"
                   )

    alter table(:ledger_accounts) do
      remove :updated_at
      remove :inserted_at
      remove :currency
      remove :identifier
    end

    drop_if_exists unique_index(:ledger_balances, [:account_id, :transfer_id],
                     name: "ledger_balances_unique_references_index"
                   )

    drop constraint(:ledger_balances, "ledger_balances_account_id_fkey")

    alter table(:ledger_balances) do
      modify :account_id, :uuid
    end

    drop constraint(:ledger_transfers, "ledger_transfers_from_account_id_fkey")

    drop constraint(:ledger_transfers, "ledger_transfers_to_account_id_fkey")

    alter table(:ledger_transfers) do
      modify :to_account_id, :uuid
      modify :from_account_id, :uuid
    end

    drop table(:ledger_accounts)

    drop constraint(:ledger_balances, "ledger_balances_transfer_id_fkey")

    drop table(:ledger_balances)

    drop table(:ledger_transfers)

    drop table(:tokens)

    drop_if_exists unique_index(:users, [:email], name: "users_unique_email_index")

    drop table(:users)
  end
end
