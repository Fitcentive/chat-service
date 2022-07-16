defmodule ChatWeb.ChatController do
  use ChatWeb, :controller

  alias Chat.Repo.Chats


  def index(conn, _params) do
    render(conn, "index.html")
  end

  def testauth(conn, _params) do
    text(conn, "From messenger")
  end

  def server_health(conn, _params) do
    send_resp(conn, :ok, "Server is alive!")
  end

  def get_chat_room(conn, %{"current_user" => current_user, "target_user" => target_user}) do
    user_id = conn.assigns[:claims]["user_id"]
    room_name = [current_user, target_user]
                                      |> Enum.sort
                                      |> Enum.join("-")
    room_id = UUID.uuid5(:nil, room_name)
    new_room = %{id: room_id, name: room_name, type: "private"}

    with room <- Chats.upsert_room(new_room) do
      render(conn, "show_room.json", room: room)
    end
  end

  def get_room_messages(conn,  %{"room_id" => room_id}) do
    user_id = conn.assigns[:claims]["user_id"]

    with messages <- Chats.get_messages(room_id) do
      render(conn, "show_messages.json", messages: messages)
    end
  end


end
