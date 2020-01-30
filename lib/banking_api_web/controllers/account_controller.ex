defmodule BankingApiWeb.AccountController do
  use BankingApiWeb, :controller

  import Guardian.Plug

  alias BankingApi.Bank
  alias BankingApi.Bank.Account

  require Logger

  action_fallback BankingApiWeb.FallbackController

  def index(conn, _params) do
    accounts = Bank.list_accounts()
    render(conn, "index.json", accounts: accounts)
  end

  # def create(conn, %{"account" => account_params}) do
  #   with {:ok, %Account{} = account} <- Bank.create_account(account_params) do
  #     conn
  #     |> put_status(:created)
  #     |> put_resp_header("location", Routes.account_path(conn, :show, account))
  #     |> render("show.json", account: account)
  #   end
  # end

  def show(conn, %{"id" => id}) do
    account = Bank.get_account!(id)
    render(conn, "show.json", account: account)
  end

  def show_current_account(conn, _params) do
    current_user = current_resource(conn)

    account = Bank.get_account!(current_user.account.id)
    render(conn, "show.json", account: account)
  end

  def update(conn, %{"id" => id, "account" => account_params}) do
    account = Bank.get_account!(id)

    with {:ok, %Account{} = account} <- Bank.update_account(account, account_params) do
      render(conn, "show.json", account: account)
    end
  end

  def withdraw(conn, %{"amount" => amount}) do
    try do
      current_user = current_resource(conn)

      with {:ok, %{account: account, transaction: transaction}} <-
             Bank.withdraw(current_user.account.id, amount) do
        Logger.info("Account Withdraw - Sending email to client...")
        render(conn, "show.json", %{account: account, transaction: transaction})
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

  def transfer(conn, %{"destination_account_id" => destination_account_id, "amount" => amount}) do
    try do
      current_user = current_resource(conn)
      source_account_id = current_user.account.id

      with {:ok, %{account: account, transaction: transaction}} <-
             Bank.transfer(source_account_id, destination_account_id, amount) do
        Logger.info("Transfer Money Between Accounts - Sending email to clients...")
        render(conn, "show.json", %{account: account, transaction: transaction})
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
end
