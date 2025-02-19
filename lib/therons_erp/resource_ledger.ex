defmodule TheronsErp.ResourceLedger do
  use Ash.Domain, otp_app: :therons_erp, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource TheronsErp.ResourceLedger.Account
    resource TheronsErp.ResourceLedger.Balance
    resource TheronsErp.ResourceLedger.Transfer
  end
end
