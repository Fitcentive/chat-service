defmodule ChatWeb.GcpPubSubSubscriber do

  alias ChatWeb.GcpPubSubSubscriber
  alias Kane

  use GenServer
  use WebSockex

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    subscribe_to_stateful_chat_room_message_sent_event()
  end

  def pubsub_config do
    {config, _} =
      :gcp_pubsub_subscriber
      |> Application.get_env(__MODULE__, %{})
      |> Keyword.split([:config])

    case config do
      [config: config_map] -> config_map
      _ -> raise "No config found for #{__MODULE__}"
    end
  end

  def pod_name do
    {config, _} =
      :gcp_pubsub_subscriber
      |> Application.get_env(__MODULE__, %{})
      |> Keyword.split([:config])

    case config do
      [config: config_map] -> config_map["pod_name"]
      _ -> raise "No config found for #{__MODULE__}"
    end
  end

  def subscribe_to_stateful_chat_room_message_sent_event() do
    {:ok, token} = Goth.fetch(Chat.Goth)

    config = ChatWeb.GcpPubSubSubscriber.pubsub_config
    pubsub_topics = config["topics"]

    topic = %Kane.Topic{name: pubsub_topics[:chat_room_message_sent]}

    kane = %Kane{
      project_id: config["project_id"],
      token: token
    }

    subscription = %Kane.Subscription{
      name: "#{pubsub_topics[:chat_room_message_sent]}-#{pod_name()}",
      topic: %Kane.Topic{
        name: topic
      }
    }

    # Could result in error, we do not care, it is idempotent
    Kane.Subscription.create(kane, subscription)

    Kane.Subscription.stream(kane, subscription)
    |> Enum.map(fn message ->
          process_message(message)
          Kane.Subscription.ack(kane, subscription, message)
       end)

  end

  defp process_message(pubsub_message) do
    message =
    %{
      "topic" => topic,
      "id" => id,
      "payload" => %{
        "sendingUser" => sending_user,
        "targetUser" => target_user,
        "roomId" => room_id,
        "message" => messageText,
        "messageSender" => messageSender,
      }
    } = Poison.decode!(pubsub_message.data)

    if messageSender != pod_name do
      notify_channel_if_needed(room_id, sending_user, messageText)
    end

  end

  defp notify_channel_if_needed(room_id, sending_user_id, message) do
    config = ChatWeb.GcpPubSubSubscriber.pubsub_config

    {:ok, newSocket} =
      WebSockex.start(
        "ws://127.0.0.1:4000/api/chat/socket/websocket?secret=#{config["secret"]}",
        __MODULE__,
        :fake_state, []
      )

    WebSockex.send_frame(newSocket, {:text, Poison.encode!(%{
      topic: "chat_room:#{room_id}",
      event: "phx_join",
      payload: %{},
      ref: UUID.uuid4(),
      join_ref: UUID.uuid4()
    })})

    WebSockex.send_frame(newSocket, {:text, Poison.encode!(%{
      topic: "chat_room:#{room_id}",
      event: "echo",
      payload: %{
        body: message,
        user_id: sending_user_id,
      },
      ref: UUID.uuid4(),
      join_ref: UUID.uuid4()
    })})

    WebSockex.send_frame(newSocket, {:close, 1000, "Closing message"})
  end

end