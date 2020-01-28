defmodule BankingApiWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use BankingApiWeb, :controller
  require Logger

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(BankingApiWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, :bad_request}) do
    conn
    |> put_status(:bad_request)
    |> put_view(BankingApiWeb.ErrorView)
    |> render(:"400")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(BankingApiWeb.ErrorView)
    |> render(:"401")
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(BankingApiWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, :invalid_value_withdraw}) do
    body = Poison.encode!(%{errors: %{detail: "Invalid Value (Must be greater than 0.00)"}})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, body)
  end

  def call(conn, {:error, :insufficient_balance}) do
    body = Poison.encode!(%{errors: %{detail: "Insufficient Balance"}})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, body)
  end

  def call(conn, {:error, :invalid_destination_account}) do
    body = Poison.encode!(%{errors: %{detail: "Invalid Destination Account"}})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, body)
  end
end
