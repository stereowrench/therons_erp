defmodule TheronsErp.People do
  use Ash.Domain, otp_app: :therons_erp, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource TheronsErp.People.Entity do
      define :list_people, action: :read
    end

    resource TheronsErp.People.Address do
    end
  end
end
