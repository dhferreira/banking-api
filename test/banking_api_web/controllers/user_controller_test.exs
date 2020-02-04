defmodule BankingApiWeb.UserControllerTest do
  use BankingApiWeb.ConnCase

  alias BankingApi.Auth
  alias BankingApi.Auth.Guardian
  # alias BankingApi.Auth.User

  @create_attrs %{
    name: "some test name",
    email: "test@email.com.br",
    password: "some password",
    is_active: true
  }
  @create_admin_attrs %{
    name: "some name",
    email: "email@email.com.br",
    password: "some password",
    is_active: true,
    permission: "ADMIN"
  }
  @update_attrs %{
    name: "some updated name",
    email: "email_updated@email.com.br",
    password: "some updated password",
    is_active: false,
    permission: "ADMIN"
  }
  @invalid_attrs %{email: "some_wrong_email", is_active: nil, name: nil, permission: "OTHER"}

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

    test "raises unauthenticated when user not signed in", %{conn: conn} do
      conn = conn |> put_req_header("authorization", "")
      conn = get(conn, Routes.user_path(conn, :index))

      assert %{
               "errors" => %{
                 "detail" => "unauthenticated"
               }
             } == json_response(conn, 401)
    end

    test "lists all users when admin user signedup", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_path(conn, :index))

      assert [
               %{
                 "id" => user.id,
                 "email" => user.email,
                 "name" => user.name,
                 "is_active" => user.is_active,
                 "permission" => user.permission,
                 "account" => %{
                   "id" => user.account.id,
                   "balance" => Decimal.to_string(user.account.balance)
                 }
               }
             ] == json_response(conn, 200)["data"]

      # creates one more user
      new_user = fixture(:user)
      conn = get(conn, Routes.user_path(conn, :index))

      assert [
               %{
                 "id" => user.id,
                 "email" => user.email,
                 "name" => user.name,
                 "is_active" => user.is_active,
                 "permission" => user.permission,
                 "account" => %{
                   "id" => user.account.id,
                   "balance" => Decimal.to_string(user.account.balance)
                 }
               },
               %{
                 "id" => new_user.id,
                 "email" => new_user.email,
                 "name" => new_user.name,
                 "is_active" => new_user.is_active,
                 "permission" => new_user.permission,
                 "account" => %{
                   "id" => new_user.account.id,
                   "balance" => Decimal.to_string(new_user.account.balance)
                 }
               }
             ] == json_response(conn, 200)["data"]
    end
  end

  describe "index - default permission" do
    setup [:create_user]

    test "raises unauthorized when listing users for a default user signedup", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :index))

      assert %{
               "errors" => %{
                 "detail" => "unauthorized"
               }
             } == json_response(conn, 401)
    end
  end

  describe "show - admin permission" do
    setup [:create_admin_user]

    test "renders an user given a valid ID", %{conn: conn} do
      %{:id => id} = fixture(:user)

      conn = get(conn, Routes.user_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "name" => "some test name",
               "email" => "test@email.com.br",
               "is_active" => true,
               "permission" => "DEFAULT",
               "account" => account
             } = json_response(conn, 200)["data"]
    end

    test "raises not found for not found ID", %{conn: conn} do
      fixture(:user)

      assert_error_sent 404, fn ->
        get(conn, Routes.user_path(conn, :show, Ecto.UUID.generate()))
      end
    end
  end

  describe "show - default permission" do
    setup [:create_user]

    test "raises unathorized when user with default permission", %{conn: conn} do
      user = fixture(:admin_user)

      conn = get(conn, Routes.user_path(conn, :show, user))

      assert %{
               "errors" => %{
                 "detail" => "unauthorized"
               }
             } == json_response(conn, 401)
    end
  end

  describe "show signed in user - admin permission" do
    setup [:create_admin_user]

    test "renders own user", %{conn: conn, user: user} do
      %{:id => id} = user

      conn = get(conn, Routes.user_path(conn, :show_current_user))

      assert %{
               "id" => ^id
             } = json_response(conn, 200)["data"]
    end
  end

  describe "show signed in user - default permission" do
    setup [:create_user]

    test "renders own user", %{conn: conn, user: user} do
      %{:id => id} = user

      conn = get(conn, Routes.user_path(conn, :show_current_user))

      assert %{
               "id" => ^id
             } = json_response(conn, 200)["data"]
    end
  end

  describe "create user - admin permission" do
    setup [:create_admin_user]

    test "renders user when data is valid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)

      assert %{
               "id" => id,
               "email" => "test@email.com.br",
               "name" => "some test name",
               "is_active" => true,
               "permission" => "DEFAULT",
               "account" => account
             } = json_response(conn, 201)["data"]

      conn = get(conn, Routes.user_path(conn, :show, id))

      assert %{
               "id" => id,
               "email" => "test@email.com.br",
               "name" => "some test name",
               "is_active" => true,
               "permission" => "DEFAULT",
               "account" => account
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "create user - default permission" do
    setup [:create_user]

    test "raises unauthorized when creating a new user", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :create), user: @create_admin_attrs)

      assert %{
               "errors" => %{
                 "detail" => "unauthorized"
               }
             } == json_response(conn, 401)
    end
  end

  describe "sign up" do
    test "renders user when data is valid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :signup), user: @create_attrs)

      assert %{
               "id" => id,
               "email" => "test@email.com.br",
               "name" => "some test name",
               "is_active" => true,
               "permission" => "DEFAULT",
               "account" => account,
               "token" => token
             } = json_response(conn, 201)["data"]

      # set authentication token
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> put_req_header("accept", "application/json")

      conn = get(conn, Routes.user_path(conn, :show_current_user))

      assert %{
               "id" => id,
               "email" => "test@email.com.br",
               "name" => "some test name",
               "is_active" => true,
               "permission" => "DEFAULT",
               "account" => account
             } = json_response(conn, 200)["data"]
    end

    test "ensures only users with DEFAULT permission can be created", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :signup), user: @create_admin_attrs)

      assert %{
               "id" => id,
               "email" => "email@email.com.br",
               "name" => "some name",
               "is_active" => true,
               "permission" => "DEFAULT",
               "account" => account,
               "token" => token
             } = json_response(conn, 201)["data"]

      # set authentication token
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> put_req_header("accept", "application/json")

      conn = get(conn, Routes.user_path(conn, :show_current_user))

      assert %{
               "id" => id,
               "email" => "email@email.com.br",
               "name" => "some name",
               "is_active" => true,
               "permission" => "DEFAULT",
               "account" => account
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :signup), user: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update user - admin permission" do
    setup [:create_admin_user]

    test "renders user when data is valid", %{conn: conn} do
      user = fixture(:user)

      %{:id => id} = user

      conn = put(conn, Routes.user_path(conn, :update, user), user: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.user_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "name" => "some updated name",
               "email" => "email_updated@email.com.br",
               "is_active" => false,
               "permission" => "ADMIN",
               "account" => account
             } = json_response(conn, 200)["data"]
    end

    test "ensures that ID can not be updated", %{conn: conn} do
      user = fixture(:user)

      %{:id => id} = user

      conn =
        put(conn, Routes.user_path(conn, :update, user),
          user: %{name: "Test new ID", id: Ecto.UUID.generate()}
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.user_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "name" => "Test new ID",
               "email" => "test@email.com.br",
               "is_active" => true,
               "permission" => "DEFAULT",
               "account" => account
             } = json_response(conn, 200)["data"]
    end

    test "raises error response when user not found", %{conn: conn} do
      fixture(:user)

      assert_error_sent 404, fn ->
        put(conn, Routes.user_path(conn, :update, Ecto.UUID.generate()), user: @update_attrs)
      end
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update user - default permission" do
    setup [:create_user]

    test "raises unauthorized when updating an user", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_path(conn, :update, user), user: @update_attrs)

      assert %{
               "errors" => %{
                 "detail" => "unauthorized"
               }
             } == json_response(conn, 401)
    end
  end

  describe "update own user - default permission" do
    setup [:create_user]

    test "ensures that user with default permission can't change its permission", %{
      conn: conn,
      user: user
    } do
      %{:id => id} = user

      conn =
        put(conn, Routes.user_path(conn, :update_current_user),
          user: %{name: "Test new name", permission: "ADMIN"}
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.user_path(conn, :show_current_user))

      assert %{
               "id" => ^id,
               "name" => "Test new name",
               "email" => "test@email.com.br",
               "is_active" => true,
               "permission" => "DEFAULT",
               "account" => account
             } = json_response(conn, 200)["data"]
    end

    test "renders user when data is valid", %{conn: conn, user: user} do
      %{:id => id} = user

      conn = put(conn, Routes.user_path(conn, :update_current_user), user: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.user_path(conn, :show_current_user))

      assert %{
               "id" => ^id,
               "name" => "some updated name",
               "email" => "email_updated@email.com.br",
               "is_active" => true,
               "permission" => "DEFAULT",
               "account" => account
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = put(conn, Routes.user_path(conn, :update_current_user), user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update own user - admin permission" do
    setup [:create_admin_user]

    test "renders user when data is valid", %{conn: conn, user: user} do
      %{:id => id} = user

      conn = put(conn, Routes.user_path(conn, :update_current_user), user: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.user_path(conn, :show_current_user))

      assert %{
               "id" => ^id,
               "name" => "some updated name",
               "email" => "email_updated@email.com.br",
               "is_active" => false,
               "permission" => "ADMIN",
               "account" => account
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = put(conn, Routes.user_path(conn, :update_current_user), user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete user with admin permission" do
    setup [:create_admin_user]

    test "deletes chosen user", %{conn: conn} do
      user = fixture(:user)

      conn = delete(conn, Routes.user_path(conn, :delete_user, user))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.user_path(conn, :show, user))
      end
    end

    test "raises error response when user not found", %{conn: conn} do
      fixture(:user)

      assert_error_sent 404, fn ->
        delete(conn, Routes.user_path(conn, :delete_user, Ecto.UUID.generate()))
      end
    end
  end

  describe "delete user with default permission" do
    setup [:create_user]

    test "raises unauthorized when deleting an user", %{conn: conn} do
      user = fixture(:admin_user)
      conn = get(conn, Routes.user_path(conn, :delete_user, user))

      assert %{
               "errors" => %{
                 "detail" => "unauthorized"
               }
             } == json_response(conn, 401)
    end
  end

  describe "sign in" do
    test "given valid credentials", %{conn: conn} do
      fixture(:user)

      conn =
        post(conn, Routes.user_path(conn, :signin), %{
          email: @create_attrs.email,
          password: @create_attrs.password
        })

      assert response(conn, 200)
    end

    test "given invalid credentials or missing parameters (email and/or password)", %{conn: conn} do
      fixture(:user)

      conn =
        post(conn, Routes.user_path(conn, :signin), %{
          email: @create_attrs.email,
          password: "some wrong email"
        })

      assert response(conn, 401)
    end

    test "given missing parameters (email and/or password)", %{conn: conn} do
      fixture(:user)

      conn = post(conn, Routes.user_path(conn, :signin), %{email: @create_attrs.email})
      assert response(conn, 400)

      conn = post(conn, Routes.user_path(conn, :signin), %{})
      assert response(conn, 400)
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
