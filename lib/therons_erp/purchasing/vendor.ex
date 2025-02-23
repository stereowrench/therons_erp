defmodule TheronsErp.Purchasing.Vendor do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Purchasing,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "vendors"
    repo TheronsErp.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string
    attribute :address, :string
    attribute :phone, :string
    attribute :email, :string
    attribute :city, :string
    attribute :state, :string
    attribute :zip_code, :string

    attribute :identifier, :integer do
      generated? true
    end

    timestamps()
  end

  relationships do
    has_many :purchase_orders, TheronsErp.Purchasing.PurchaseOrder

    has_many :replenishments, TheronsErp.Purchasing.Replenishment
  end
end
