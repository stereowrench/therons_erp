defmodule TheronsErp.Repo do
  use Ecto.Repo,
    otp_app: :therons_erp,
    adapter: Ecto.Adapters.Postgres
end
