defmodule TheronsErp.Ledger do
  use Ash.Domain, otp_app: :therons_erp, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource TheronsErp.Ledger.Account
    resource TheronsErp.Ledger.Balance
    resource TheronsErp.Ledger.Transfer
  end
end
