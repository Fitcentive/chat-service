defmodule Chat.Repo.Migrations.CreateUserLastSeenTable do
  use Ecto.Migration
  alias Chat.Schema.UserLastSeen

  def change do
    create table(:user_last_seen, primary_key: false) do
      add :room_id, references(:room, column: :id, on_delete: :delete_all, type: :uuid), primary_key: true
      add :user_id, references(:user, column: :id, on_delete: :delete_all, type: :uuid), primary_key: true
      add :last_seen, :utc_datetime, null: false

      timestamps([inserted_at: :created_at, type: :utc_datetime])
    end

  end
end
