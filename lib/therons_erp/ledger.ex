defmodule TheronsErp.Ledger do
  use Ash.Domain,
    otp_app: :therons_erp

  resources do
    resource TheronsErp.Ledger.Account
    resource TheronsErp.Ledger.Balance
    resource TheronsErp.Ledger.Transfer
  end
end
