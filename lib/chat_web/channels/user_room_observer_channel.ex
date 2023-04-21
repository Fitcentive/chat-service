defmodule ChatWeb.UserRoomObserverChannel do
  use ChatWeb, :channel

  alias ChatWeb.Presence

  import Chat.Repo.Chats
  alias Chat.Repo.Chats
  alias ChatWeb.GcpPubSubClient
  alias ChatWeb.UserRoomObserverChannel

  @impl true
  def join("user_room_observer:" <> user_id_channel_param, %{"user_id" => user_id} = payload, socket) do
    if authorized?(user_id_channel_param, user_id, socket) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def join("user_room_observer:" <> user_id_channel_param, payload, socket) do
    {:ok, assign(socket, :user_id, user_id_channel_param)}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  @impl true
  def handle_in("user_room_updated", %{"room_id" => roomId} = payload, socket) do
    broadcast(socket, "user_room_updated", payload)
    {:noreply, socket}
  end

  defp authorized?(user_id_channel_param, user_id, socket) do
    socket.assigns[:user_id] == user_id_channel_param and socket.assigns[:user_id] == user_id
  end

end
