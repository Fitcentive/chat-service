defmodule Chat.Repo.Migrations.CreateRoomTable do
  use Ecto.Migration
  alias Chat.Schema.Room

  def change do
    create table(:room, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string
      add :type, :string

      timestamps([inserted_at: :created_at, type: :utc_datetime])
    end

  end
end
