defmodule TheronsErp.Invoices.LineItem do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Invoices,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "line_items"
    repo TheronsErp.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    uuid_primary_key :id

    attribute :price, :money
    attribute :quantity, :integer
    timestamps()
  end

  relationships do
    belongs_to :invoice, TheronsErp.Invoices.Invoice do
      allow_nil? false
    end

    belongs_to :product, TheronsErp.Inventory.Product do
      allow_nil? false
    end
  end
end
