defmodule BankingApiWeb.AccountControllerTest do
  use BankingApiWeb.ConnCase

  alias BankingApi.Auth
  alias BankingApi.Auth.Guardian

  @create_attrs %{
    name: "some test name",
    email: "test@email.com.br",
    password: "some password"
  }
  @create_admin_attrs %{
    name: "some name",
    email: "email@email.com.br",
    password: "some password",
    permission: "ADMIN"
  }

  def fixture(:user) do
    {:ok, user} = Auth.create_user(@create_attrs)
    user
  end

  def fixture(:admin_user) do
    {:ok, user} = Auth.create_user(@create_admin_attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index - admin permission" do
    setup [:create_admin_user]

    test "lists all accounts", %{conn: conn, user: user} do
      %{:id => id} = user.account

      conn = get(conn, Routes.account_path(conn, :index))

      assert [
               %{
                 "id" => ^id,
                 "balance" => "1000.00"
               }
             ] = json_response(conn, 200)["data"]

      # insert one more user with account
      new_user = fixture(:user)

      %{:id => new_id} = new_user.account

      conn = get(conn, Routes.account_path(conn, :index))

      assert [
               %{
                 "id" => ^id,
                 "balance" => "1000.00"
               },
               %{
                 "id" => ^new_id,
                 "balance" => "1000.00"
               }
             ] = json_response(conn, 200)["data"]
    end
  end

  describe "index - default permission" do
    setup [:create_user]

    test "returns unauthorized error response for listing all accounts", %{conn: conn} do
      conn = get(conn, Routes.account_path(conn, :index))

      assert %{
               "errors" => %{
                 "detail" => "unauthorized"
               }
             } == json_response(conn, 401)
    end
  end

  describe "show - admin permission" do
    setup [:create_admin_user]

    test "lists an account given an valid ID", %{conn: conn, user: user} do
      %{:id => id} = user.account

      conn = get(conn, Routes.account_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "balance" => "1000.00"
             } = json_response(conn, 200)["data"]

      # insert one more user with account
      new_user = fixture(:user)

      %{:id => new_id} = new_user.account

      conn = get(conn, Routes.account_path(conn, :show, new_id))

      assert %{
               "id" => ^new_id,
               "balance" => "1000.00"
             } = json_response(conn, 200)["data"]
    end

    test "return an error response given an invalid ID", %{conn: conn} do
      assert_error_sent 404, fn ->
        get(conn, Routes.account_path(conn, :show, Ecto.UUID.generate()))
      end

      assert_error_sent 400, fn -> get(conn, Routes.account_path(conn, :show, "123")) end
      assert_error_sent 400, fn -> get(conn, Routes.account_path(conn, :show, 123)) end

      assert_error_sent 400, fn ->
        get(conn, Routes.account_path(conn, :show, "some invalid id"))
      end
    end
  end

  describe "show - default permission" do
    setup [:create_user]

    test "return unauthorized error response for listing account give an ID", %{
      conn: conn,
      user: user
    } do
      conn = get(conn, Routes.account_path(conn, :show, user.account.id))

      assert %{
               "errors" => %{
                 "detail" => "unauthorized"
               }
             } == json_response(conn, 401)
    end
  end

  describe "show_current_account" do
    setup [:create_user]

    test "return the account of the logged in user", %{conn: conn, user: user} do
      %{:id => id} = user.account

      conn = get(conn, Routes.account_path(conn, :show_current_account))

      assert %{
               "id" => ^id,
               "balance" => "1000.00",
               "user" => user
             } = json_response(conn, 200)["data"]
    end
  end

  defp create_user(%{conn: conn}) do
    fixture(:user)
    {:ok, user, token} = Guardian.authenticate(@create_attrs.email, @create_attrs.password)

    conn = put_req_header(conn, "authorization", "Bearer #{token}")

    {:ok, %{user: user, conn: conn}}
  end

  defp create_admin_user(%{conn: conn}) do
    fixture(:admin_user)

    {:ok, user, token} =
      Guardian.authenticate(@create_admin_attrs.email, @create_admin_attrs.password)

    conn = put_req_header(conn, "authorization", "Bearer #{token}")

    {:ok, %{user: user, conn: conn}}
  end
end
