defmodule TheronsErp.People do
  use Ash.Domain,
    otp_app: :therons_erp

  resources do
    resource TheronsErp.People.Entity
    resource TheronsErp.People.Address
  end
end
