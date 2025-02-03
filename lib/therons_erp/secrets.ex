defmodule TheronsErp.Secrets do
  use AshAuthentication.Secret

  def secret_for([:authentication, :tokens, :signing_secret], TheronsErp.Accounts.User, _opts) do
    Application.fetch_env(:therons_erp, :token_signing_secret)
  end
end
