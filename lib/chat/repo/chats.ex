defmodule Chat.Repo.Chats do
  import Ecto.Query, warn: false

  alias Chat.Repo
  alias Ecto.Multi

  alias Chat.Schema.Message
  alias Chat.Schema.MessageMetadata
  alias Chat.Schema.Room
  alias Chat.Schema.RoomUser
  alias Chat.Schema.User
  alias Chat.Schema.UserLastSeen
  alias Chat.Schema.RoomAdmins

  alias Chat.Repo.Chats

  @behaviour Bodyguard.Policy

  def authorize(:get_room_messages, user_id, room_id) do
    case Chats.get_room_user_if_exists(room_id, user_id) do
      nil -> :error
      _   -> :ok
    end
  end

  def authorize(:check_if_user_belongs_to_room, user_id, room_id) do
    case Chats.get_room_user_if_exists(room_id, user_id) do
      nil -> :error
      _   -> :ok
    end
  end

  def authorize(:check_if_user_is_room_admin, user_id, room_id) do
    case Chats.get_room_admins(room_id) do
      nil      -> :error
      admins   ->
        case Enum.map(admins, fn admin -> admin.user_id end) |> Enum.member?(user_id) do
          true  -> :ok
          false -> :error
        end
    end
  end

  def authorize(:check_if_user_exists, user_id, _) do
    case Chats.get_user_if_exists(user_id) do
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

  def authorize(:check_if_all_users_exist, user_id, target_users) do
    case Chats.get_user_if_exists(user_id) do
      nil -> :error
      _   ->
        case target_users
             |> Enum.map(fn user -> Chats.get_user_if_exists(user)  end)
             |> Enum.all?() do
          true -> :ok
          false -> :error
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

  defp room_admin_changeset(room_admin_params) do
    RoomAdmins.changeset(
      %RoomAdmins{},
      Map.merge(room_admin_params, %{})
    )
  end

  defp user_last_seen_changeset(room_user_params) do
    UserLastSeen.changeset(
      %UserLastSeen{},
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

  def upsert_room_admin(room_admin_params) do
    Repo.insert!(
      room_admin_changeset(room_admin_params),
      on_conflict: {:replace, [:updated_at]},
      conflict_target: [:room_id, :user_id],
      returning: true,
    )
  end

  def upsert_user_last_seen(room_user_params) do
    Repo.insert!(
      user_last_seen_changeset(room_user_params),
      on_conflict: {:replace, [:last_seen, :updated_at]},
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

  def enable_room(room_id) do
    query =
      from room in Room,
           where: room.id == ^room_id,
           update: [set: [enabled: true]]

    query
    |> Repo.update_all([])
  end

  def disable_room(room_id) do
    query =
      from room in Room,
           where: room.id == ^room_id,
           update: [set: [enabled: false]]

    query
    |> Repo.update_all([])
  end

  def remove_user_from_room(room_id, user_id) do
    {:ok, user_id_uuid} = Ecto.UUID.dump(user_id)
    {:ok, room_id_uuid} = Ecto.UUID.dump(room_id)
    query =
      from room_user in RoomUser,
      where: room_user.room_id == ^room_id_uuid and room_user.user_id == ^user_id_uuid

    query
    |> Repo.delete_all
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
      from m in Message,
           distinct: m.room_id,
           where: m.room_id in ^room_ids,
           order_by: [asc: m.room_id, desc: m.created_at],
           select: %{room_id: m.room_id, most_recent_message: m.text, most_recent_message_time: m.created_at}
    query
    |> Repo.all
  end

  def most_recent_room_messages(room_id) do
    query =
      from m in Message,
           distinct: m.room_id,
           where: m.room_id == ^room_id,
           order_by: [asc: m.room_id, desc: m.created_at],
           select: %{room_id: m.room_id, most_recent_message: m.text, most_recent_message_time: m.created_at}
    query
    |> Repo.one
  end

  def get_room_definitions(room_ids, user_id) do
    query =
      from room in Room,
      left_join: room_user in RoomUser,
      on: room_user.room_id == room.id,
      select: %{
         id: room.id,
         name: room.name,
         type: room.type,
         created_at: room.created_at,
         updated_at: room.updated_at
      },
      where: room_user.user_id == ^user_id and room.id in ^room_ids

    query
    |> Repo.all
  end

  # We need to filter by user enabled rooms here
  def get_user_rooms(user_id) do
    enabled_rooms = Repo.all(
      from room in Room,
      select: room.id,
      where: room.enabled
    )

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
      ) and room_user.room_id in ^enabled_rooms,
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

  def get_detailed_user_room_by_id(user_id, room_id) do
    query =
      from r in Room,
           join: ru in RoomUser, on: r.id == ru.room_id,
           left_join: m in Message, on: m.room_id == r.id,
           group_by: r.id,
           order_by: fragment("MAX(?) DESC", m.created_at),
           where: r.enabled and r.id == ^room_id,
           select: %{
             room: r,
             users: fragment("array(select distinct unnest(array_agg(?)))", ru.user_id),
             most_recent_message: fragment("(array_agg(? ORDER BY ? DESC))[1]", m.text, m.created_at),
             most_recent_message_timestamp: max(m.created_at)
           }

    result = Repo.one(query)
  end

  def get_detailed_user_rooms(user_id, room_limit, room_offset) do
    user_allowed_chat_rooms_query =
      from room_user in RoomUser,
           select: %{
             room_id: room_user.room_id,
           },
           where: room_user.user_id == ^user_id

    query =
      from r in Room,
           join: ru in RoomUser, on: r.id == ru.room_id,
           left_join: m in Message, on: m.room_id == r.id,
           group_by: r.id,
           order_by: fragment("MAX(COALESCE(?, ?)) DESC", m.created_at, r.created_at),
           where: r.enabled and r.id in subquery(user_allowed_chat_rooms_query),
           select: %{
             room: r,
             users: fragment("array(select distinct unnest(array_agg(?)))", ru.user_id),
             most_recent_message: fragment("(array_agg(? ORDER BY ? DESC))[1]", m.text, m.created_at),
             most_recent_message_timestamp: max(m.created_at)
           },
           limit: ^room_limit,
           offset: ^room_offset

    result = Repo.all(query)
  end

  def get_messages(room_id, sent_before, _limit) do
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
        where: message.room_id == ^room_id and message.created_at < ^sent_before,
        order_by: [desc: message.created_at],
        distinct: true,
        limit: ^_limit
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

  def get_user_last_seen_if_exists(room_id, user_id) do
    query =
      from user_last_seen in UserLastSeen,
      select: user_last_seen,
      where: user_last_seen.room_id == ^room_id and user_last_seen.user_id == ^user_id

    query
    |> Repo.one
  end

  def get_user_last_seen_if_exists_for_rooms(room_ids, user_id) do
    query =
      from user_last_seen in UserLastSeen,
           select: user_last_seen,
           where: user_last_seen.room_id in ^room_ids and user_last_seen.user_id == ^user_id

    query
    |> Repo.all
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

  def update_room_users([], user_id) do
    :ok
  end

  def update_room_users(room_ids, user_id, deleted_user_id) do
    {:ok, deleted_user_id_uuid} = Ecto.UUID.dump(deleted_user_id)
    {:ok, user_id_uuid} = Ecto.UUID.dump(user_id)
    query =
      from room_user in RoomUser,
      where: room_user.room_id in ^room_ids and room_user.user_id == ^user_id_uuid,
      update: [set: [user_id: ^deleted_user_id_uuid]]

    query
      |> Repo.update_all([])
  end

  def update_room_name(room_id, room_name) do
    query =
      from room in Room,
           where: room.id == ^room_id,
           update: [set: [name: ^room_name]]

    query
    |> Repo.update_all([])
  end

  def update_messages(user_id, deleted_user_id) do
    {:ok, deleted_user_id_uuid} = Ecto.UUID.dump(deleted_user_id)
    {:ok, user_id_uuid} = Ecto.UUID.dump(user_id)
    query =
      from message in Message,
      where: message.sender_id == ^user_id,
      update: [set: [sender_id: ^deleted_user_id_uuid]]

    query
      |> Repo.update_all([])
  end

  def delete_user(user_id) do
    query =
      from user in User,
      where: user.id == ^user_id

    query
      |> Repo.delete_all()
  end

  def delete_room(room_id) do
    query =
      from room in Room,
           where: room.id == ^room_id

    query
    |> Repo.delete_all()
  end

  def get_room_admins(room_id) do
    query =
      from room_admin in RoomAdmins,
        where: room_admin.room_id == ^room_id

    query
      |> Repo.all()
  end

  def remove_admin_for_room(room_id, user_id) do
    query =
      from room_admin in RoomAdmins,
           where: room_admin.room_id == ^room_id and room_admin.user_id == ^user_id

    query
    |> Repo.delete_all()
  end

end