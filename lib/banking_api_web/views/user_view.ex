defmodule BankingApiWeb.UserView do
  use BankingApiWeb, :view
  alias BankingApiWeb.UserView

  require Logger

  def render("index.json", %{users: users}) do
    %{data: render_many(users, UserView, "user.json")}
  end

  def render("show.json", %{user: user, token: token, account: account}) do
    %{data: render(UserView, "user.json", %{user: user, token: token, account: account})}
  end

  def render("show.json", %{user: user}) do
    %{data: render_one(user, UserView, "user.json")}
  end

  def render("user.json", %{user: user, token: token, account: account}) do
    %{
      id: user.id,
      name: user.name,
      email: user.email,
      is_active: user.is_active,
      permission: user.permission,
      token: token,
      account: %{
        id: account.id,
        balance: account.balance
      }
    }
  end

  def render("user.json", %{user: user, token: token}) do
    %{
      id: user.id,
      name: user.name,
      email: user.email,
      is_active: user.is_active,
      permission: user.permission,
      token: token
    }
  end

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      name: user.name,
      email: user.email,
      is_active: user.is_active,
      permission: user.permission
    }
  end
end
