defmodule BankingApi.Auth.Guardian do
  @moduledoc """
  Guardian functions for authentication
  """
  use Guardian, otp_app: :banking_api

  require Logger

  alias Argon2
  alias BankingApi.Auth

  def subject_for_token(user, _claims) do
    sub = to_string(user.id)
    {:ok, sub}
  end

  def resource_from_claims(%{"sub" => id}) do
    case Auth.get_user(id) do
      nil -> {:erro, :resource_not_found}
      user -> {:ok, user}
    end
  end

  def authenticate(email, password) do
    user = Auth.get_user_by_email(email)
    if user do
      case Argon2.check_pass(user, password) do
        {:error, _msg} ->
          {:error, :unauthorized}
        {:ok, user} ->
          {:ok, token, _claims} = encode_and_sign(user)
          {:ok, user, token}
      end
    else
      {:error, :unauthorized}
    end
  end
end
