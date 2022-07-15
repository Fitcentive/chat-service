defmodule Chat.Repo.Chats do
  import Ecto.Query, warn: false

  alias Chat.Repo

  alias Chat.Schema.Message
  alias Chat.Schema.MessageMetadata
  alias Chat.Schema.Room
  alias Chat.Schema.RoomUser
  alias Chat.Schema.User

  defp room_changeset(room_params) do
    Room.changeset(
      %Room{},
      Map.merge(room_params, %{})
    )
  end

  defp user_changeset(user_params) do
    User.changeset(
      %User{},
      Map.merge(user_params, %{})
    )
  end

  def upsert_user(user_params) do
    Repo.insert!(
      user_changeset(user_params),
      on_conflict: {:replace, [:updated_at, :is_active, :first_name, :last_name]},
      conflict_target: :id,
      returning: true,
    )
  end


  def upsert_room(room_params) do
    Repo.insert!(
      room_changeset(room_params),
      on_conflict: {:replace, [:updated_at, :name]},
      conflict_target: :id,
      returning: true,
    )
  end




end