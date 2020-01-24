defmodule BankingApiWeb.UserControllerTest do
  use BankingApiWeb.ConnCase

  alias BankingApi.Auth
  alias BankingApi.Auth.Guardian
  alias BankingApi.Auth.User

  @create_attrs %{
    name: "some name",
    email: "email@email.com.br",
    password: "some password",
    is_active: true
  }
  @update_attrs %{
    name: "some updated name",
    email: "email_updated@email.com.br",
    password: "some updated password",
    is_active: false
  }
  @invalid_attrs %{email: nil, is_active: nil, name: nil}
  @valid_credentials %{
    email: "email@email.com.br",
    password: "some password",
  }
  @invalid_credentials %{
    email: "email@email.com.br",
    password: "some wrong password",
  }

  def fixture(:user) do
    {:ok, user} = Auth.create_user(@create_attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all users", %{conn: conn} do
      user = fixture(:user)
      {:ok, user, token} = Guardian.authenticate(@valid_credentials.email, @valid_credentials.password)

      conn = conn
      |> put_req_header(conn, "authorization", "Bearer #{token}")
      |> get(Routes.user_path(conn, :index))

      assert json_response(conn, 200)["data"] == [
        %{
          id: user.id,
          name: user.name,
          email: user.email,
          is_active: user.is_active,
          permission: user.permission,
          account: %{
            id: user.account.id,
            balance: user.account.balance
          }
        }
      ]
    end
  end

  # describe "create user" do
  #   test "renders user when data is valid", %{conn: conn} do
  #     conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)

  #     assert %{
  #              "id" => id,
  #              "email" => "email@email.com.br",
  #              "name" => "some name",
  #              "is_active" => true,
  #              "token" => token
  #            } = json_response(conn, 201)["data"]

  #     conn = get(conn, Routes.user_path(conn, :show, id))

  #     assert %{
  #              "id" => id,
  #              "email" => "email@email.com.br",
  #              "is_active" => true
  #            } = json_response(conn, 200)["data"]
  #   end

  #   test "renders errors when data is invalid", %{conn: conn} do
  #     conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
  #     assert json_response(conn, 422)["errors"] != %{}
  #   end
  # end

  # describe "update user" do
  #   setup [:create_user]

  #   test "renders user when data is valid", %{conn: conn, user: %User{id: id} = user} do
  #     conn = put(conn, Routes.user_path(conn, :update, user), user: @update_attrs)
  #     assert %{"id" => ^id} = json_response(conn, 200)["data"]

  #     conn = get(conn, Routes.user_path(conn, :show, id))

  #     assert %{
  #              "id" => id,
  #              "email" => "email_updated@email.com.br",
  #              "is_active" => false
  #            } = json_response(conn, 200)["data"]
  #   end

  #   test "renders errors when data is invalid", %{conn: conn, user: user} do
  #     conn = put(conn, Routes.user_path(conn, :update, user), user: @invalid_attrs)
  #     assert json_response(conn, 422)["errors"] != %{}
  #   end
  # end

  # describe "delete user" do
  #   setup [:create_user]

  #   test "deletes chosen user", %{conn: conn, user: user} do
  #     conn = delete(conn, Routes.user_path(conn, :delete, user))
  #     assert response(conn, 204)

  #     assert_error_sent 404, fn ->
  #       get(conn, Routes.user_path(conn, :show, user))
  #     end
  #   end
  # end

  # describe "signin" do
  #   setup [:create_user]

  #   test "given valid credentials", %{conn: conn} do
  #     conn = post(conn, Routes.user_path(conn, :signin), @valid_credentials)
  #     assert response(conn, 200)
  #   end

  #   test "given invalid credentials or missing parameters (email and/or password)", %{conn: conn} do
  #     conn = post(conn, Routes.user_path(conn, :signin), @invalid_credentials)
  #     assert response(conn, 401)
  #   end
  # end

  # defp create_user(_) do
  #   user = fixture(:user)
  #   {:ok, user: user}
  # end
end
