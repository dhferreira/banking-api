defmodule BankingApi.Banking.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    field :balance, :decimal, precision: 8, scale: 2
    belongs_to :user, BankingApi.Auth.User
    has_many :transaction, BankingApi.Banking.Transaction
    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:balance])
    |> validate_required([:balance])
    |> validate_number(:balance, greater_than_or_equal_to: 0)
  end
end
