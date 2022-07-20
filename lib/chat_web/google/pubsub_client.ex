defmodule ChatWeb.GcpPubSubClient do

  alias ChatWeb.GcpPubSubClient

  def pubsub_config do
    {config, _} =
      :gcp_pubsub_client
      |> Application.get_env(__MODULE__, %{})
      |> Keyword.split([:topics])

    case config do
      [topics: topics] -> topics
      _                -> raise "No config present for #{__MODULE__}"
    end
  end


  def publish_chat_room_message_sent(sending_user, target_user, room_id, message) do
    # todo - dont read this each time
    pubsub_topics = ChatWeb.GcpPubSubClient.pubsub_config
    topic = %Kane.Topic{name: pubsub_topics[:chat_room_message_sent]}
    message = %Kane.Message{
      data: %{
        topic: pubsub_topics[:chat_room_message_sent],
        id: UUID.uuid4(),
        payload: %{
          "sendingUser": sending_user,
          "targetUser": target_user,
          "roomId": room_id,
          "message": message
        }
      }
    }

    result = Kane.Message.publish(message, topic)
    case result do
      {:ok, _result}   -> IO.puts("Published to topic successfully")
      {:error, reason} -> IO.puts("Publish failure with reason #{reason}")
    end
  end

end