defmodule BankingApi.Auth.Guardian do
  @moduledoc """
  Guardian functions for User's authentication
  """
  use Guardian, otp_app: :banking_api

  require Logger

  alias Argon2
  alias BankingApi.Auth

  def subject_for_token(user, _claims) do
    sub = to_string(user.id)
    {:ok, sub}
  end

  @doc """
  Get user from given token
  """
  def resource_from_claims(%{"sub" => id}) do
    case Auth.get_user(id) do
      nil -> {:erro, :resource_not_found}
      user -> {:ok, user}
    end
  end

  @doc """
  Descodes permissions from given token
  """
  def decode_permissions_from_claims(%{"perms" => perms}) do
    if perms do
      perms
    else
      %{}
    end
  end

  @doc """
  Check if logged in user has all permissions needed
  """
  def all_permissions?(user_permissions, check_permissions) do
    Enum.all?(
      Map.keys(check_permissions),
      fn role ->
        if Map.has_key?(user_permissions, Atom.to_string(role)) do
          Enum.all?(
            Map.get(check_permissions, role),
            fn permission ->
              Enum.member?(
                Map.get(user_permissions, Atom.to_string(role)),
                Atom.to_string(permission)
              )
            end
          )
        else
          false
        end
      end
    )
  end

  @doc """
  Authenticates given credentials, checking if email and password are corrected and user is active.
  """
  def authenticate(email, password) do
    user = Auth.get_user_by_email(email)

    if user && user.is_active do
      case Argon2.check_pass(user, password) do
        {:error, _msg} ->
          {:error, :unauthorized}

        {:ok, user} ->
          perms =
            if user.permission === "ADMIN" do
              %{default: [:banking], admin: [:backoffice]}
            else
              %{default: [:banking]}
            end

          with {:ok, token, _claims} <- encode_and_sign(user, %{perms: perms}) do
            {:ok, user, token}
          end
      end
    else
      {:error, :unauthorized}
    end
  end
end
