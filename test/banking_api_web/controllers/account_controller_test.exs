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

  describe "withdraw" do
    setup [:create_user]

    test "withdraw money when given valid amount and balance is enough", %{conn: conn, user: user} do
      %{:id => id} = user.account

      conn = post(conn, Routes.account_path(conn, :withdraw, %{amount: "100"}))

      assert %{
               "account" => %{
                 "id" => ^id,
                 "balance" => "900.00"
               },
               "transaction" => transaction
             } = json_response(conn, 200)["data"]

      conn = post(conn, Routes.account_path(conn, :withdraw, %{amount: "500"}))

      assert %{
               "account" => %{
                 "id" => ^id,
                 "balance" => "400.00"
               },
               "transaction" => transaction
             } = json_response(conn, 200)["data"]
    end

    test "returns error response when Account's balance is not enough for the amount withdraw request",
         %{conn: conn} do
      conn = post(conn, Routes.account_path(conn, :withdraw, %{amount: "20000"}))

      assert %{
               "errors" => %{
                 "detail" => "Insufficient Balance"
               }
             } == json_response(conn, 400)
    end

    test "returns error response when given invalid amount (lower or equal to 0.00)",
         %{conn: conn} do
      conn = post(conn, Routes.account_path(conn, :withdraw, %{amount: "-25"}))

      assert %{
               "errors" => %{
                 "detail" => "Invalid Amount (Must be a number greater than 0.00)"
               }
             } == json_response(conn, 400)
    end
  end

  describe "transfer" do
    setup [:create_admin_user]

    test "transfer money when given valid amount, source account balance is enough, and destination account is valid",
         %{conn: conn, user: user} do
      %{:id => source_account_id} = user.account

      destinatio_user = fixture(:user)
      %{:id => destination_account_id} = destinatio_user.account

      conn =
        post(
          conn,
          Routes.account_path(conn, :transfer, %{
            amount: "100",
            destination_account_id: destination_account_id
          })
        )

      assert %{
               "account" => %{
                 "id" => ^source_account_id,
                 "balance" => "900.00"
               },
               "transaction" => %{
                 "value" => "100.00",
                 "source_account_id" => ^source_account_id,
                 "destination_account_id" => ^destination_account_id
               }
             } = json_response(conn, 200)["data"]

      conn = get(conn, Routes.account_path(conn, :show, destination_account_id))

      assert %{
               "id" => ^destination_account_id,
               "balance" => "1100.00"
             } = json_response(conn, 200)["data"]
    end

    test "returns error response when Account's balance is not enough for the amount withdraw request",
         %{conn: conn} do
      destinatio_user = fixture(:user)
      %{:id => destination_account_id} = destinatio_user.account

      conn =
        post(
          conn,
          Routes.account_path(conn, :transfer, %{
            amount: "20000",
            destination_account_id: destination_account_id
          })
        )

      assert %{
               "errors" => %{
                 "detail" => "Insufficient Balance"
               }
             } == json_response(conn, 400)
    end

    test "returns error response when given invalid amount (lower or equal to 0.00)",
         %{conn: conn} do
      destinatio_user = fixture(:user)
      %{:id => destination_account_id} = destinatio_user.account

      conn =
        post(
          conn,
          Routes.account_path(conn, :withdraw, %{
            amount: "-25",
            destination_account_id: destination_account_id
          })
        )

      assert %{
               "errors" => %{
                 "detail" => "Invalid Amount (Must be a number greater than 0.00)"
               }
             } == json_response(conn, 400)
    end

    test "returns error response when given invalid destination account",
         %{conn: conn} do
      conn =
        post(
          conn,
          Routes.account_path(conn, :transfer, %{
            amount: "100",
            destination_account_id: Ecto.UUID.generate()
          })
        )

      assert %{
               "errors" => %{
                 "detail" => "Destination Account Not Found"
               }
             } == json_response(conn, 404)
    end

    test "returns error response when source and destination account are the same",
         %{conn: conn, user: user} do
      %{:id => source_account_id} = user.account

      conn =
        post(
          conn,
          Routes.account_path(conn, :transfer, %{
            amount: "100",
            destination_account_id: source_account_id
          })
        )

      assert %{
               "errors" => %{
                 "detail" => "Source and Destination accounts are the same."
               }
             } == json_response(conn, 400)
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
