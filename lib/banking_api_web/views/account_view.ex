defmodule BankingApiWeb.AccountView do
  use BankingApiWeb, :view
  alias BankingApiWeb.AccountView

  def render("index.json", %{accounts: accounts}) do
    %{data: render_many(accounts, AccountView, "account.json")}
  end

  def render("show.json", %{account: account, transaction: transaction}) do
    %{data: render(AccountView, "account.json", %{account: account, transaction: transaction})}
  end

  def render("show.json", %{account: account}) do
    %{data: render_one(account, AccountView, "account.json")}
  end

  def render("account.json", %{account: account, transaction: transaction}) do
    %{
      account: %{
        id: account.id,
        balance: account.balance,
      },
      transaction: %{
        id: transaction.id,
        description: transaction.description,
        value: transaction.value,
        source_account_id: transaction.account_id,
        created_at: transaction.inserted_at
      }
    }
  end

  def render("account.json", %{account: account}) do
    %{
      id: account.id,
      balance: account.balance,
      user: %{
        id: account.user.id,
        name: account.user.name,
        email: account.user.email
      }
    }
  end
end
