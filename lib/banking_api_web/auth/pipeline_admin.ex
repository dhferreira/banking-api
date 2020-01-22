defmodule BankingApiWeb.Auth.PipelineAdmin do
  use Guardian.Plug.Pipeline, otp_app: :banking_api,
    module: BankingApi.Auth.Guardian,
    error_handler: BankingApiWeb.Auth.ErrorHandler

  plug Guardian.Permissions.Bitwise, ensure: %{admin: [:backoffice]}
end
