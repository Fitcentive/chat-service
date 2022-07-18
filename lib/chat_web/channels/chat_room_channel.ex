defmodule ChatWeb.ChatRoomChannel do
  use ChatWeb, :channel

  import Chat.Repo.Chats
  alias Chat.Repo.Chats

  # todo - Use Phoenix.presence to track user active status
  @impl true
  def join("chat_room:" <> room_id, %{"user_id" => user_id} = payload, socket) do
    if authorized?(room_id, user_id, socket) do
      {:ok, assign(socket, :room_id, room_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end


  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end


  @impl true
  def handle_in("shout", %{"body" => text, "image_url" => image_url} = payload, socket) do
    room_id = socket.assigns[:room_id]
    user_id = socket.assigns[:user_id]
    with message <- Chats.create_message_with_metadata(%{
      "sender_id" => user_id,
      "room_id" => room_id,
      "text" => text,
      "image_url" => image_url,
    }) do
      broadcast(socket, "shout", payload)
      {:noreply, socket}
    end
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (chat_room:lobby).
  @impl true
  def handle_in("shout", %{"body" => text} = payload, socket) do
    room_id = socket.assigns[:room_id]
    user_id = socket.assigns[:user_id]
    with message <- Chats.create_message(%{
      "sender_id" => user_id,
      "room_id" => room_id,
      "text" => text,
    }) do
      broadcast(socket, "shout", payload)
      {:noreply, socket}
    end
  end

  defp authorized?(room_id, user_id, socket) do
    if (socket.assigns[:user_id] == user_id) do
      case Bodyguard.permit(Chats, :get_room_messages, user_id, room_id) do
        :ok -> true
        _   -> false
      end
    else
      false
    end
  end



end
