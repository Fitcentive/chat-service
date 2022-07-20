defmodule Chat.Repo.Chats do
  import Ecto.Query, warn: false

  alias Chat.Repo
  alias Ecto.Multi

  alias Chat.Schema.Message
  alias Chat.Schema.MessageMetadata
  alias Chat.Schema.Room
  alias Chat.Schema.RoomUser
  alias Chat.Schema.User

  alias Chat.Repo.Chats

  @behaviour Bodyguard.Policy

  def authorize(:get_room_messages, user_id, room_id) do
    case Chats.get_room_user_if_exists(room_id, user_id) do
      nil -> :error
      _   -> :ok
    end
  end

  def authorize(:check_if_users_exist, user_id, target_user) do
    case Chats.get_user_if_exists(user_id) do
      nil -> :error
      _   ->
        case Chats.get_user_if_exists(target_user) do
          nil -> :error
          _   -> :ok
        end
    end
  end

  #----------------------------------------------------------------------------

  defmacro array_agg(field) do
    quote do: fragment("array_agg(?)", unquote(field))
  end

  defmacro array_agg_most_recent(field) do
    quote do: fragment("(array_agg(? order by created_at desc))[1]", unquote(field))
  end

  #----------------------------------------------------------------------------

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

  defp message_changeset(message_params) do
    Message.changeset(
      %Message{},
      Map.merge(message_params, %{})
    )
  end

  defp message_metadata_changeset(message_metadata_params) do
    MessageMetadata.changeset(
      %MessageMetadata{},
      Map.merge(message_metadata_params, %{})
    )
  end

  defp room_user_changeset(room_user_params) do
    RoomUser.changeset(
      %RoomUser{},
      Map.merge(room_user_params, %{})
    )
  end

  #------------------------------------------------------------------------------------------------------------

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

  def upsert_room_user(room_user_params) do
    Repo.insert!(
      room_user_changeset(room_user_params),
      on_conflict: {:replace, [:updated_at]},
      conflict_target: [:room_id, :user_id],
      returning: true,
    )
  end

  def create_message(message_params) do
    Repo.insert!(
      message_changeset(message_params),
      returning: true,
    )
  end

  def create_message_metadata(message_metadata_params) do
    Repo.insert!(
      message_metadata_changeset(message_metadata_params),
      on_conflict: {:replace, [:updated_at, :image_url]},
      conflict_target: :id,
      returning: true,
    )
  end

  # Todo - replace with with Ecto.Multi
  def create_message_with_metadata(%{
    "sender_id" => user_id,
    "room_id" => room_id,
    "text" => text,
    "image_url" => image_url,
  }) do
    with new_message <- create_message(%{
      "sender_id" => user_id,
      "room_id" => room_id,
      "text" => text,
    }) do
      create_message_metadata(%{
        "message_id" => new_message.id,
        "image_url" => image_url
      })
    end
  end

  # todo - merge this with user rooms to save API call
  def most_recent_room_messages(room_ids) do
    query =
      from message in Message,
           select: %{
             room_id: message.room_id,
             most_recent_message: array_agg_most_recent(message.text)
           },
           where: message.room_id in ^room_ids,
           group_by: [message.room_id]
    query
    |> Repo.all
  end

  def get_user_rooms(user_id) do
    cte_query =
      from room_user in RoomUser,
      left_join: message in Message,
      on: room_user.room_id == message.room_id,
      select: %{
                room_id: room_user.room_id,
                user_id: room_user.user_id,
                most_recent_message_time: max(message.created_at),
      },
      where: room_user.room_id in subquery(
        from room_user in RoomUser,
        select: %{
          room_id: room_user.room_id
        },
        where: room_user.user_id == ^user_id
      ),
      group_by: [room_user.room_id, room_user.user_id]

    result = "t1"
      |> with_cte("t1", as: ^cte_query)
      |> select([row], %{
          room_id: row.room_id,
          user_ids: array_agg(row.user_id),
          most_recent_message_time: max(row.most_recent_message_time)
        })
      |> group_by([row], [row.room_id, row.most_recent_message_time])
      |> order_by([row], [desc: row.most_recent_message_time])
      |> Repo.all

  end

  def get_messages(room_id) do
    query =
      from message in Message,
        left_join: message_metadata in MessageMetadata,
        on: message.id == message_metadata.message_id,
        select: %{
          id: message.id,
          sender_id: message.sender_id,
          room_id: message.sender_id,
          text: message.text,
          created_at: message.created_at,
          updated_at: message.updated_at,
          image_url: message_metadata.image_url,
        },
        where: message.room_id == ^room_id,
        order_by: [desc: message.created_at],
        distinct: true

    query
    |> Repo.all
  end

  def get_room_user_if_exists(room_id, user_id) do
    query =
      from room_user in RoomUser,
      select: room_user,
      where: room_user.room_id == ^room_id and room_user.user_id == ^user_id

  query
    |> Repo.one

  end

  def get_user_if_exists(user_id) do
    query =
      from user in User,
      select: user,
      where: user.id == ^user_id

    query
      |> Repo.one
  end

  def get_users_for_room(room_id) do
    query =
      from room_user in RoomUser,
      select: %{
         room_id: room_user.room_id,
         user_ids: array_agg(room_user.user_id),
       },
      where: room_user.room_id == ^room_id,
      group_by: room_user.room_id

    query
     |> Repo.one
  end

end