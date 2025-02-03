defmodule TheronsErp.Accounts do
  use Ash.Domain,
    otp_app: :therons_erp

  resources do
    resource TheronsErp.Accounts.Token
    resource TheronsErp.Accounts.User
  end
end
