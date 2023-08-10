defmodule ChatWeb.GcpPubSubClient do

  alias ChatWeb.GcpPubSubClient

  def pubsub_config do
    {config, _} =
      :gcp_pubsub_client
      |> Application.get_env(__MODULE__, %{})
      |> Keyword.split([:config])

    case config do
      [config: config_map] -> config_map
      _ -> raise "No config found for #{__MODULE__}"
    end
  end

  def pod_name do
    {config, _} =
      :gcp_pubsub_client
      |> Application.get_env(__MODULE__, %{})
      |> Keyword.split([:config])

    case config do
      [config: config_map] -> config_map["pod_name"]
      _ -> raise "No config found for #{__MODULE__}"
    end
  end

  # We not only publish a message for sending push notification but also to other pods incase users are connected to websockets there
  def publish_chat_room_message_sent(sending_user, target_user, room_id, message) do
    # todo - dont read this each time
    pubsub_config = ChatWeb.GcpPubSubClient.pubsub_config
    pubsub_topics = pubsub_config["topics"]
    topic = %Kane.Topic{name: pubsub_topics[:chat_room_message_sent]}
    message = %Kane.Message{
      data: %{
        topic: pubsub_topics[:chat_room_message_sent],
        id: UUID.uuid4(),
        payload: %{
          "sendingUser": sending_user,
          "targetUser": target_user,
          "roomId": room_id,
          "message": message,
          "messageSender": pod_name,
        }
      }
    }

    {:ok, token} = Goth.fetch(Chat.Goth)
    kane = %Kane{
      project_id: pubsub_config["project_id"],
      token: token
    }

    result = Kane.Message.publish(kane, message, topic)
    case result do
      {:ok, _result}   -> IO.puts("Published to topic successfully")
      {:error, reason} -> IO.puts("Publish failure with reason #{reason}")
    end
  end

end