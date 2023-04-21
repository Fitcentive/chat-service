defmodule ChatWeb.RoomObserverChannel do
  use ChatWeb, :channel

  alias ChatWeb.Presence

  import Chat.Repo.Chats
  alias Chat.Repo.Chats
  alias ChatWeb.GcpPubSubClient
  alias ChatWeb.RoomObserverChannel

  @impl true
  def join("room_observer:" <> room_id, %{"user_id" => user_id} = payload, socket) do
    if authorized?(room_id, user_id, socket) do
      {:ok, assign(socket, :room_id, room_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def join("room_observer:" <> room_id, payload, socket) do
    {:ok, assign(socket, :room_id, room_id)}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  @impl true
  def handle_in("room_updated", %{"room_id" => roomId} = payload, socket) do
    broadcast(socket, "room_updated", payload)
    {:noreply, socket}
  end

  defp authorized?(room_id, user_id, socket) do
    if (socket.assigns[:user_id] == user_id) do
      case Bodyguard.permit(Chats, :get_room_messages, user_id, room_id) do
        :ok -> true
        _   -> false
      end
    else
      # In this case, there is no socket.assigns[:user_id] as it might be an internal communication
      case Bodyguard.permit(Chats, :get_room_messages, user_id, room_id) do
        :ok -> true
        _   -> false
      end
    end
  end

end
