defmodule BankingApi.Auth do
  @moduledoc """
  The Auth context.
  """
  import Ecto.Query, warn: false

  alias BankingApi.Auth.User
  alias BankingApi.Banking
  alias BankingApi.Repo
  alias Ecto.Multi

  require Logger
  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    User
    |> Repo.all()
    |> Repo.preload([:account])
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id) do
    User
    |> Repo.get!(id)
    |> Repo.preload([:account])
  end

  @doc """
  Gets a single user.

  Return nil if the User does not exist.

  ## Examples

      iex> get_user(123)
      %User{}

      iex> get_user(456)
      nil

  """
  def get_user(id) do
    User
    |> Repo.get(id)
    |> Repo.preload([:account])
  end

  @doc """
  Gets a single user by its email.

  Returns nil if the User with specified email does not exist.

  ## Examples

      iex> get_user_by_email("teste@teste.com")
      %User{}

      iex> get_user_by_email("usuario@teste.com")
      nil

  """
  def get_user_by_email(email) do
    User
    |> Repo.get_by(email: email)
    |> Repo.preload([:account])
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  # def create_user(attrs \\ %{}) do
  #   %User{}
  #   |> User.changeset(attrs)
  #   |> Repo.insert()
  # end
  def create_user(attrs \\ %{}) do
    Multi.new()
    |> Multi.insert(:user, User.changeset(%User{}, attrs))
    |> Multi.run(:account, fn _repo, %{user: user} -> Banking.create_account(%{balance: 1000.00, user_id: user.id}) end)#When user signs up, receives R$ 1000,00
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user, account: _account}}  ->
        {:ok, get_user!(user.id)}
      {:error, _entity, changeset, _changes_so_far} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset_update(attrs)
    |> Repo.update()
    |> case do
      {:ok, user} -> {:ok, Repo.preload(user, :account)}
      error -> error
    end
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end
end
