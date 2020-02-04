defmodule BankingApiWeb.TransactionControllerTest do
  use BankingApiWeb.ConnCase

  alias BankingApi.Auth
  alias BankingApi.Auth.Guardian
  alias BankingApi.Bank

  @create_attrs %{
    description: "some description",
    value: "120.5"
  }

  @create_user_attrs %{
    name: "some test name",
    email: "test@email.com.br",
    password: "some password"
  }
  @create_admin_user_attrs %{
    name: "some name",
    email: "email@email.com.br",
    password: "some password",
    permission: "ADMIN"
  }

  def fixture(:user) do
    {:ok, user} = Auth.create_user(@create_user_attrs)
    user
  end

  def fixture(:admin_user) do
    {:ok, user} = Auth.create_user(@create_admin_user_attrs)
    user
  end

  def transaction_fixture(user, attrs \\ %{}) do
    {:ok, transaction} =
      attrs
      |> Enum.into(%{source_account_id: user.account.id})
      |> Enum.into(@create_attrs)
      |> Bank.create_transaction()

    transaction
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index - admin permission" do
    setup [:create_admin_user]

    test "lists all transactions", %{conn: conn, user: user} do
      transaction = transaction_fixture(user)

      %{:id => id} = transaction

      conn = get(conn, Routes.transaction_path(conn, :index))

      assert [
               %{
                 "id" => ^id
               }
             ] = json_response(conn, 200)["data"]

      # creates one more transaction
      new_transaction = transaction_fixture(user)
      %{:id => new_id} = new_transaction

      conn = get(conn, Routes.transaction_path(conn, :index))

      assert [
               %{
                 "id" => ^id
               },
               %{
                 "id" => ^new_id
               }
             ] = json_response(conn, 200)["data"]
    end
  end

  describe "index - default permission" do
    setup [:create_user]

    test "returns unauthorized error response for listing all transactions", %{conn: conn} do
      conn = get(conn, Routes.transaction_path(conn, :index))

      assert %{
               "errors" => %{
                 "detail" => "unauthorized"
               }
             } == json_response(conn, 401)
    end
  end

  describe "show_current_account_transaction" do
    setup [:create_user]

    test "return account's transaction of the logged in user", %{conn: conn, user: user} do
      transaction = transaction_fixture(user)
      %{:id => id} = transaction

      conn = get(conn, Routes.transaction_path(conn, :show_current_account_transaction))

      assert [
               %{
                 "id" => ^id
               }
             ] = json_response(conn, 200)["data"]
    end
  end

  describe "transactions_report - admin permission" do
    setup [:create_admin_user]

    test "returns a report with sum of transaction's values by month, year, day and total", %{
      conn: conn,
      user: user
    } do
      # transaction = transaction_fixture(user)
      # %{:id => id} = transaction

      conn = get(conn, Routes.transaction_path(conn, :transactions_report))

      assert %{
               "day" => [],
               "month" => [],
               "total" => "0.00",
               "year" => []
             } == json_response(conn, 200)["data"]

      # Add some transactions

      transaction_fixture(user, %{value: 150})
      transaction_fixture(user, %{value: 180})

      conn = get(conn, Routes.transaction_path(conn, :transactions_report))

      assert %{
               "total" => "330.00"
             } = json_response(conn, 200)["data"]
    end
  end

  describe "transactions_report - default permission" do
    setup [:create_user]

    test "returns unauthorized error response for generate report of transactions", %{conn: conn} do
      conn = get(conn, Routes.transaction_path(conn, :transactions_report))

      assert %{
               "errors" => %{
                 "detail" => "unauthorized"
               }
             } == json_response(conn, 401)
    end
  end

  defp create_user(%{conn: conn}) do
    fixture(:user)

    {:ok, user, token} =
      Guardian.authenticate(@create_user_attrs.email, @create_user_attrs.password)

    conn = put_req_header(conn, "authorization", "Bearer #{token}")

    {:ok, %{user: user, conn: conn}}
  end

  defp create_admin_user(%{conn: conn}) do
    fixture(:admin_user)

    {:ok, user, token} =
      Guardian.authenticate(@create_admin_user_attrs.email, @create_admin_user_attrs.password)

    conn = put_req_header(conn, "authorization", "Bearer #{token}")

    {:ok, %{user: user, conn: conn}}
  end
end
