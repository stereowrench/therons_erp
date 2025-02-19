defmodule TheronsErp.Accounts do
  use Ash.Domain, otp_app: :therons_erp, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource TheronsErp.Accounts.Token
    resource TheronsErp.Accounts.User
  end
end
