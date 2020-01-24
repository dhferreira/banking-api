defmodule BankingApi.AuthTest do
  use BankingApi.DataCase

  alias BankingApi.Auth

  describe "users" do
    alias BankingApi.Auth.User

    @valid_attrs %{
      email: "email@email.com.br",
      is_active: true,
      name: "some name",
      password: "some password",
      permission: "DEFAULT"
    }
    @update_attrs %{
      email: "email.updated@email.com.br",
      is_active: false,
      name: "some updated name",
      password: "some updated password",
      permission: "ADMIN"
    }
    @invalid_attrs %{email: nil, is_active: nil, name: nil, password: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Auth.create_user()

      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()

      assert Auth.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Auth.get_user!(user.id) == user
    end

    test "get_user!/1 raise exception when user not found" do
      user_fixture()
      assert_raise Ecto.NoResultsError, fn -> Auth.get_user!(Ecto.UUID.generate()) end
    end

    test "get_user/1 returns the user with given id" do
      user = user_fixture()
      assert Auth.get_user(user.id) == user
    end

    test "get_user/1 returns nil when user not found" do
      user_fixture()
      assert Auth.get_user(Ecto.UUID.generate()) == nil
    end

    test "get_user_by_email/1 returns the user with given id" do
      user = user_fixture()
      assert Auth.get_user_by_email(user.email) == user
    end

    test "get_user_by_email/1 returns nil with invalid email" do
      user_fixture()
      assert Auth.get_user_by_email("teste") == nil
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Auth.create_user(@valid_attrs)
      assert user.email == "email@email.com.br"
      assert user.is_active == true
      assert user.name == "some name"
      assert user.permission == "DEFAULT"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Auth.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Auth.update_user(user, @update_attrs)
      assert user.email == "email.updated@email.com.br"
      assert user.is_active == false
      assert user.name == "some updated name"
      assert user.permission == "ADMIN"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Auth.update_user(user, @invalid_attrs)
      assert user == Auth.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Auth.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Auth.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Auth.change_user(user)
    end
  end
end
