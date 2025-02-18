defmodule TheronsErp.Invoices.LineItem do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Invoices,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "line_items"
    repo TheronsErp.Repo
  end

  code_interface do
    define :create, args: []
  end

  actions do
    defaults [:read]

    create :create do
      accept [:price, :quantity, :invoice_id, :product_id]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :price, :money do
      allow_nil? false
    end

    attribute :quantity, :integer do
      allow_nil? false
    end

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

  calculations do
    calculate :total_price, :money, expr(sales_price * quantity)
  end
end
