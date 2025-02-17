defmodule TheronsErp.Sales do
  use Ash.Domain,
    otp_app: :therons_erp

  resources do
    resource TheronsErp.Sales.SalesOrder do
      define :create_draft, action: :create, args: []
    end

    resource TheronsErp.Sales.SalesLine
  end
end
