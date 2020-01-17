defmodule BankingApi.Auth.Guardian do
  @moduledoc """
  Guardian functions for authentication
  """
  use Guardian, otp_app: :banking_api

  alias BankingApi.Auth

  def subject_for_token(user, _claims) do
    sub = to_string(user.id)
    {:ok, sub}
  end

  def resource_from_claims(claims) do
    id = claims["sub"]
    resource = Auth.get_user!(id)
    {:ok, resource}
  end

  def authenticate(email, password) do
    with {:ok, user} <- Auth.get_user_by_email(email) do
      case check_password(user, password) do
        true ->
          create_token(user)

        false ->
          {:error, :unauthorized}
      end
    end
  end

  defp check_password(user, password) do
    Argon2.check_pass(user, password)
  end

  defp create_token(user) do
    {:ok, token, _claims} = Guardian.encode_and_sign(user)
    {:ok, user, token}
  end
end
