defmodule ChatWeb.ChatController do
  use ChatWeb, :controller

  alias Chat.Repo.Chats

  action_fallback ChatWeb.FallbackController

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def testauth(conn, _params) do
    text(conn, "From messenger")
  end

  def server_health(conn, _params) do
    send_resp(conn, :ok, "Server is alive!")
  end

  def upsert_user(conn, _params) do
    user_id = conn.assigns[:claims]["user_id"]
    first_name = conn.assigns[:claims]["given_name"]
    last_name = conn.assigns[:claims]["family_name"]

    with _ <- Chats.upsert_user(%{id: user_id, first_name: first_name, last_name: last_name, is_active: false}) do
      send_resp(conn, :ok, "Success")
    end
  end

  def get_chat_room(conn, %{"target_user" => target_user}) do
    user_id = conn.assigns[:claims]["user_id"]
    room_name = [user_id, target_user]
                                      |> Enum.sort
                                      |> Enum.join("-")
    room_id = UUID.uuid5(:nil, room_name)
    new_room = %{id: room_id, name: room_name, type: "private"}

    with :ok <- Bodyguard.permit(Chats, :check_if_users_exist, user_id, target_user),
        room <- Chats.upsert_room(new_room),
         _ <- Chats.upsert_room_user(%{"room_id" => room.id, "user_id" => user_id}),
         _ <- Chats.upsert_room_user(%{"room_id" => room.id, "user_id" => target_user}) do
      render(conn, "show_room.json", room: room)
    end
  end

  def get_most_recent_room_messages(conn, %{"room_ids" => room_ids}) when is_list(room_ids) do
    user_id = conn.assigns[:claims]["user_id"]

    with bodyguard_results <- room_ids |> Enum.map(fn room_id -> Bodyguard.permit(Chats, :get_room_messages, user_id, room_id) end),
         true <- Enum.all?(bodyguard_results, &match?(:ok, &1)),
         most_recent_room_messages <- Chats.most_recent_room_messages(room_ids) do
      render(conn, "show_most_recent_room_messages.json", most_recent_room_messages: most_recent_room_messages)
    end
  end

  def get_room_messages(conn,  params = %{"room_id" => room_id}) do
    now = Integer.to_string(DateTime.utc_now |> DateTime.to_unix(:millisecond))

    user_id = conn.assigns[:claims]["user_id"]
    sent_before = Map.get(params, "sent_before", now)
    limit = Map.get(params, "limit", 50)
    {unix_timestamp, _} = Integer.parse(sent_before)
    {:ok, sent_before_param} = DateTime.from_unix(unix_timestamp, :millisecond)

    with :ok <- Bodyguard.permit(Chats, :get_room_messages, user_id, room_id),
         messages <- Chats.get_messages(room_id, sent_before_param, limit) do
      render(conn, "show_messages.json", messages: messages)
    end
  end

  def get_user_rooms(conn, _params) do
    user_id = conn.assigns[:claims]["user_id"]

    with rooms <- Chats.get_user_rooms(user_id) do
      render(conn, "show_rooms.json", rooms: rooms)
    end
  end

  def delete_user_data(conn, params = %{"user_id" => user_id}) do
    {deleted_user_id, _} = :deleted_user_id
                          |> Application.get_env(__MODULE__, %{})
                          |> Keyword.split([:user_id])

    # Steps to take
    # 1. Upsert deleted user
    # 2. Update room_user table to replace references to user being deleted
    # 3. Update message table to replace references to user being deleted
    with _ <- Chats.upsert_user(%{id: deleted_user_id[:user_id], first_name: "Deleted", last_name: "User", is_active: false}),
         user_rooms <- Chats.get_user_rooms(user_id),
         _ <- Chats.update_room_users(user_rooms, user_id, deleted_user_id),
         _ <- Chats.update_messages(user_id, deleted_user_id) do
      send_resp(conn, :no_content, "Success")
    end

  end

  defp datetime_to_epoch_milliseconds(datetime) do
    datetime
    |> Ecto.DateTime.to_erl
    |> :calendar.datetime_to_gregorian_seconds
    |> Kernel.-(62167219200)
    |> Kernel.*(1000000)
    |> Kernel.+(datetime.usec)
    |> div(1000)
    |> IO.inspect
  end

end
