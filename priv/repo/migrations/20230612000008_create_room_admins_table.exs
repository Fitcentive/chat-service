defmodule Chat.Repo.Migrations.CreateRoomAdminsTable do
  use Ecto.Migration
  alias Chat.Schema.RoomAdmins

  def change do
    create table(:room_admins, primary_key: false) do
      add :room_id, references(:room, column: :id, on_delete: :delete_all, type: :uuid), primary_key: true
      add :user_id, references(:user, column: :id, on_delete: :delete_all, type: :uuid), primary_key: true
      timestamps([inserted_at: :created_at, type: :utc_datetime])
    end

  end
end
