defmodule BankingApiWeb.Auth.PipelineAdmin do
  @moduledoc """
  Pipeline to check authentication in routes that need Admin permission
  """
  use Guardian.Plug.Pipeline,
    otp_app: :banking_api,
    module: BankingApi.Auth.Guardian,
    error_handler: BankingApiWeb.Auth.ErrorHandler

  plug Guardian.Permissions.Bitwise, ensure: %{admin: [:backoffice]}
end
