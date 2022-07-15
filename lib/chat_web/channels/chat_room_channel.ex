defmodule ChatWeb.ChatRoomChannel do
  use ChatWeb, :channel

  alias ChatWeb.Authentication.Native.VerifyToken, as: VerifyNativeAuthToken
  alias ChatWeb.Authentication.Google.VerifyToken, as: VerifyGoogleAuthToken

  # Might also have to check here to see if user is authorized to publish to the channel in question...
  @impl true
  def join("chat_room:lobby", payload, socket) do
    if authorized?(payload, socket) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def join("chat_room:" <> _private_room_id, payload, socket) do
    if authorized?(payload, socket) do
      {:ok, socket}
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

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (chat_room:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(%{"user_id" => userId, "body" => content} = payload, socket) do
    if socket.assigns[:user_id] == userId do
      true
    else
      false
    end
  end

end
