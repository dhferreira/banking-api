defmodule BankingApi.Bank.Transaction do
  @moduledoc """
  Transaction Schema

  Fields:
  - id: binary_id | UUID,
  - value: decimal, not nil
  - source_account_id: binary_id | UUID from %Account{}, not nil
  - destination_account_id: binary_id | UUID from %Account{}
  - description: string, not nil
  - inserted_at: timestamp,
  - updated_at: timestamp
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "transactions" do
    field :description, :string
    field :value, :decimal, precision: 8, scale: 2
    belongs_to :source_account, BankingApi.Bank.Account
    belongs_to :destination_account, BankingApi.Bank.Account
    timestamps()
  end

  @doc """
  Prepares changeset for transaction creation
  """
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:description, :value, :source_account_id, :destination_account_id])
    |> validate_required([:description, :value, :source_account_id])
    |> validate_number(:value, message: "invalid value")
  end
end
