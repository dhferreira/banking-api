defmodule BankingApi.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :balance, :decimal, precision: 8, scale: 2, default: 0.00

      timestamps()
    end

    create unique_index(:accounts, [:user_id])
  end
end
