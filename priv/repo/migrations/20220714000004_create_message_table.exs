defmodule Chat.Repo.Migrations.CreateMessageTable do
  use Ecto.Migration
  alias Chat.Schema.Message

  def change do
    create table(:message, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :sender_id, references(:user, column: :id, on_delete: :delete_all, type: :uuid), null: false
      add :room_id, references(:room, column: :id, on_delete: :delete_all, type: :uuid), null: false
      add :text, :string, null: false

      timestamps([inserted_at: :created_at, type: :utc_datetime])
    end

  end
end
