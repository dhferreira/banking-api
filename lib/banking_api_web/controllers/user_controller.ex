defmodule BankingApiWeb.UserController do
  @moduledoc """
  User controller
  """
  use BankingApiWeb, :controller
  require Logger

  alias BankingApi.Auth
  alias BankingApi.Auth.Guardian
  alias BankingApi.Auth.User

  action_fallback BankingApiWeb.FallbackController

  def index(conn, _params) do
    users = Auth.list_users()
    render(conn, "index.json", users: users)
  end

  def create(conn, %{"user" => user_params}) do
    case Auth.create_user(user_params) do
      # Create OK, generates access token(JWT)
      {:ok, %{user: user, account: account}} ->
        with {:ok, token, _claims} <- Guardian.encode_and_sign(user) do
          conn
            |> put_status(:created)
            |> put_resp_header("location", Routes.user_path(conn, :show, user))
            |> render("show.json", %{user: user, token: token, account: account})
        end
      # Create failed
      {:error, _entity, changeset, _changes_so_far} ->
        {:error, changeset}
    end
  end

  def show(conn, %{"id" => id}) do
    user = Auth.get_user!(id)
    render(conn, "show.json", user: user)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Auth.get_user!(id)

    with {:ok, %User{} = user} <- Auth.update_user(user, user_params) do
      render(conn, "show.json", user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Auth.get_user!(id)

    with {:ok, %User{}} <- Auth.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end

  def signin(conn, %{"email" => email, "password" => password}) do
    with {:ok, user, token} <- Guardian.authenticate(email, password) do
      conn
      |> put_status(:ok)
      |> render("user.json", %{user: user, token: token})
    end
  end
end
