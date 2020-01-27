defmodule BankingApiWeb.AccountController do
  use BankingApiWeb, :controller

  import Guardian.Plug

  alias BankingApi.Banking
  alias BankingApi.Banking.Account

  require Logger

  action_fallback BankingApiWeb.FallbackController

  def index(conn, _params) do
    accounts = Banking.list_accounts()
    render(conn, "index.json", accounts: accounts)
  end

  # def create(conn, %{"account" => account_params}) do
  #   with {:ok, %Account{} = account} <- Banking.create_account(account_params) do
  #     conn
  #     |> put_status(:created)
  #     |> put_resp_header("location", Routes.account_path(conn, :show, account))
  #     |> render("show.json", account: account)
  #   end
  # end

  def show(conn, %{"id" => id}) do
    account = Banking.get_account!(id)
    render(conn, "show.json", account: account)
  end

  # def update(conn, %{"id" => id, "account" => account_params}) do
  #   account = Banking.get_account!(id)

  #   with {:ok, %Account{} = account} <- Banking.update_account(account, account_params) do
  #     render(conn, "show.json", account: account)
  #   end
  # end

  def withdraw(conn, %{"value" => value}) do
    try do
      current_user = current_resource(conn) #get current user
      value = Decimal.cast(value) #converts to Decimal
      case Banking.withdraw(current_user.account, value) do
        {:ok, %{account: account}} ->
          Logger.info("Account Withdraw - Sending email to client...")
          render(conn, "show.json", account: account)
          ##FINISH - PLACEHOLDER
        {:error, :account, _, _} -> {:error, :insufficient_balance}
        {:error, :transaction, _, _} -> {:error, :bad_request}
        {:error, :invalid_value} -> {:error, :invalid_value_withdraw}
      end
    rescue
      err ->
        if err.message do
          Logger.error(err.message)
        else
          err |> IO.inspect() |> Logger.error()
        end
          {:error, :bad_request}
    end
  end

  def transfer(conn, %{"destination_account_id" => destination_account_id, "value" => value}) do
    try do
      current_user = current_resource(conn)
      source = current_user.account || throw("Invalid Source Account")
      destination = Banking.get_account!(destination_account_id)
      value = Decimal.cast(value) #converts to Decimal

      case Banking.transfer(source, destination, value) do
        {:ok, %{source_account: source_account}} ->
          conn
          |> put_status(:ok)
          |> render("show.json", %{account: source_account})
        {:error, :source_account, _, _} -> {:error, :insufficient_balance}
        {:error, :transaction, _, _} -> {:error, :bad_request}
        {:error, :destination_account, _, _} -> {:error, :bad_request}
      end
    rescue
      Ecto.NoResultsError -> {:error, :invalid_destination_account} #destination account not found
      Ecto.Query.CastError -> {:error, :invalid_destination_account} #invalid destination account id
      Decimal.Error -> {:error, :invalid_value_withdraw} #invalid value
      err ->
        Logger.error(err)
        {:error, :bad_request}
    end
  end
end
