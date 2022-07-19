defmodule Chat.Repo.Migrations.CreateUserTable do
  use Ecto.Migration
  alias Chat.Schema.Types.User

  def change do
    create table(:user, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :first_name, :string
      add :last_name, :string
      add :is_active, :boolean

      timestamps([inserted_at: :created_at, type: :utc_datetime])
    end

  end
end
