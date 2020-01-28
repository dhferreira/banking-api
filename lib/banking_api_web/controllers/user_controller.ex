defmodule BankingApiWeb.UserController do
  @moduledoc """
  User controller
  """
  use BankingApiWeb, :controller
  require Logger

  import Guardian.Plug

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
      # Create OK
      {:ok, %User{} = user} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", Routes.user_path(conn, :show, user))
        |> render("show.json", %{user: user})

      # Create failed
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset}
    end
  end

  def show(conn, %{"id" => id}) do
    user = Auth.get_user!(id)
    render(conn, "show.json", user: user)
  end

  def show_current_user(conn, _params) do
    current_user = current_resource(conn)
    render(conn, "show.json", user: current_user)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Auth.get_user!(id)

    with {:ok, %User{} = user} <- Auth.update_user(user, user_params) do
      render(conn, "show.json", user: user)
    end
  end

  def update_current_user(conn, %{"user" => user_params}) do
    current_user = current_resource(conn)

    user_params =
      if current_user.permission !== "ADMIN" do
        Map.delete(user_params, "permission")
      else
        user_params
      end

    with {:ok, %User{} = user} <- Auth.update_user(current_user, user_params) do
      render(conn, "show.json", user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Auth.get_user!(id)

    with {:ok, %User{}} <- Auth.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end

  def signup(conn, %{"user" => user_params}) do
    # Ensures just Users with permission DEFAULT can be created
    user_params = Map.put(user_params, "permission", "DEFAULT")

    case Auth.create_user(user_params) do
      # Create OK, generates access token(JWT)
      {:ok, %User{} = user} ->
        # set default permissions
        perms = %{default: [:banking]}

        with {:ok, token, _claims} <- Guardian.encode_and_sign(user, perms: perms) do
          conn
          |> put_status(:created)
          |> put_resp_header("location", Routes.user_path(conn, :show, user))
          |> render("show.json", %{user: user, token: token})
        end

      # Create failed
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def signin(conn, body) do
    try do
      %{"email" => email, "password" => password} = body

      with {:ok, user, token} <- Guardian.authenticate(email, password) do
        conn
        |> put_status(:ok)
        |> render("user.json", %{user: user, token: token})
      end
    rescue
      _ -> {:error, :bad_request}
    end
  end
end
