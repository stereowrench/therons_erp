defmodule TheronsErp.Sales do
  use Ash.Domain, otp_app: :therons_erp, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource TheronsErp.Sales.SalesOrder do
      define :create_draft, action: :create, args: []
    end

    resource TheronsErp.Sales.SalesLine
  end
end
