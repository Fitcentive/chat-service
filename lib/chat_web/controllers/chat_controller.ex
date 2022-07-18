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

  # todo - this has to be guarded to ensure that unauthorized user does not target user
  #        need to make API call to social service to ensure they are connected
  def get_chat_room(conn, %{"target_user" => target_user}) do
    user_id = conn.assigns[:claims]["user_id"]
    room_name = [user_id, target_user]
                                      |> Enum.sort
                                      |> Enum.join("-")
    room_id = UUID.uuid5(:nil, room_name)
    new_room = %{id: room_id, name: room_name, type: "private"}

    with room <- Chats.upsert_room(new_room),
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

  def get_room_messages(conn,  %{"room_id" => room_id}) do
    user_id = conn.assigns[:claims]["user_id"]

    with :ok <- Bodyguard.permit(Chats, :get_room_messages, user_id, room_id),
    messages <- Chats.get_messages(room_id) do
      render(conn, "show_messages.json", messages: messages)
    end
  end

  def get_user_rooms(conn, _params) do
    user_id = conn.assigns[:claims]["user_id"]

    with rooms <- Chats.get_user_rooms(user_id) do
      render(conn, "show_rooms.json", rooms: rooms)
    end
  end


end
