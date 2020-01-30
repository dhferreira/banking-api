defmodule BankingApi.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :description, :string, null: false
      add :value, :decimal, precision: 8, scale: 2, default: 0.00

      add :source_account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :destination_account_id,
          references(:accounts, type: :binary_id, on_delete: :delete_all),
          null: true

      timestamps()
    end

    create index(:transactions, [:source_account_id])
    create index(:transactions, [:destination_account_id])
  end
end
