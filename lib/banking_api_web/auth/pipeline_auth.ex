defmodule BankingApiWeb.Auth.PipelineAuth do
  use Guardian.Plug.Pipeline, otp_app: :banking_api,
    module: BankingApi.Auth.Guardian,
    error_handler: BankingApiWeb.Auth.ErrorHandler

  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end