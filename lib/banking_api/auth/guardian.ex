defmodule BankingApi.Auth.Guardian do
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
    case Auth.get_user_by_email(email) do
      {:error, :not_found} ->
        {:error, :unauthorized}
      {:ok, user} ->
        case Argon2.check_pass(user, password) do
          {:error, _msg} ->
            {:error, :unauthorized}
          {:ok, user} ->
            {:ok, token, _claims} = encode_and_sign(user)
            {:ok, user, token}
        end
    end
  end
end
