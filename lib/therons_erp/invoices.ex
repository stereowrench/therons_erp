defmodule TheronsErp.Invoices do
  use Ash.Domain,
    otp_app: :therons_erp

  resources do
    resource TheronsErp.Invoices.Invoice
    resource TheronsErp.Invoices.LineItem
  end
end
