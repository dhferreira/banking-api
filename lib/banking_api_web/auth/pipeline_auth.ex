defmodule BankingApiWeb.Auth.PipelineAuth do
  @moduledoc """
  Pipeline used for routes that need authentication (Bearer) with any permission
  """
  use Guardian.Plug.Pipeline,
    otp_app: :banking_api,
    module: BankingApi.Auth.Guardian,
    error_handler: BankingApiWeb.Auth.ErrorHandler

  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
