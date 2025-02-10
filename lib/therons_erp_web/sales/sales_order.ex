defmodule TheronsErp.Sales.SalesOrder do
  use Ash.Resource,
    otp_app: :therons_erp,
    domain: TheronsErp.Sales,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "sales_orders"
    repo TheronsErp.Repo
  end

  actions do
    defaults [:read]

    destroy :destroy do
    end

    create :create do
      argument :sales_lines, {:array, :map}

      change manage_relationship(:sales_lines, type: :create)
    end

    update :update do
      require_atomic? false
      argument :sales_lines, {:array, :map}

      change manage_relationship(:sales_lines, type: :direct_control)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :identifier, :integer do
      generated? true
    end

    timestamps()
  end

  relationships do
    has_many :sales_lines, TheronsErp.Sales.SalesLine do
      destination_attribute :sales_order_id
    end
  end

  aggregates do
    sum :total_price, [:sales_lines], :active_price
    sum :total_cost, [:sales_lines], :total_cost
  end
end
