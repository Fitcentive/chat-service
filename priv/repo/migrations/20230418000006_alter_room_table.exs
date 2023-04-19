defmodule Chat.Repo.Migrations.AlterRoomTable do
  use Ecto.Migration
  alias Chat.Schema.Room

  def change do
    alter table(:room) do
      add :enabled, :boolean, default: true
    end

  end
end
