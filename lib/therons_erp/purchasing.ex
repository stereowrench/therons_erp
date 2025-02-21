defmodule TheronsErp.Purchasing do
  use Ash.Domain,
    otp_app: :therons_erp

  resources do
    resource TheronsErp.Purchasing.Vendor
    resource TheronsErp.Purchasing.PurchaseOrder
  end
end
