defmodule Chat.Repo.Migrations.CreateMessageMetadataTable do
  use Ecto.Migration
  alias Chat.Schema.MessageMetadata

  def change do
    create table(:message_metadata, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :message_id, references(:message, column: :id, on_delete: :delete_all, type: :uuid), null: false
      add :image_url, :string

      timestamps([inserted_at: :created_at, type: :utc_datetime])
    end

  end
end
