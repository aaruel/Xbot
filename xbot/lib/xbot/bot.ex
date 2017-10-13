defmodule Xbot.Bot do
    require Logger

    defp getMessage(conn, channel_id, message_id) do
      DiscordEx.RestClient.resource(conn, :get, "channels/#{channel_id}/messages/#{message_id}")
    end

    defp parseMessage(message, id) do
        getField = fn(field) ->
            case message do
                %{^field => data} -> data
                _ -> %{}
            end
        end

        {id, getField.("attachments"), getField.("content"), getField.("author"), getField.("reactions")}
    end

    defp extractEmojiName(payload) do
        with %{"emoji" => e} <- payload,
            %{"name" => name} <- e
        do
            case name do
                "upvote" -> true
                "downvote" -> true
                _ -> false
            end
        else
            _ -> false
        end
    end

    # {id, attachments, content, author, reactions}
    defp updateDb(state, payload) do
        spawn fn ->
            %{rest_client: conn} = state
            %{"message_id" => message_id, "channel_id" => channel_id} = payload
            message = getMessage(conn, channel_id, message_id)
                |> parseMessage(message_id)

            # Send message to database
            Xbot.ETS.apply(message)
            # Send message to sockets
            Xbot.XSocket.sendToAll(Tuple.to_list(message))
        end
    end

    def handle_event({:message_reaction_add, %{data: payload}}, state) do
        if extractEmojiName(payload) do
            updateDb(state, payload)
        end
        {:ok, state}
    end

    def handle_event({:message_reaction_remove, %{data: payload}}, state) do
        if extractEmojiName(payload) do
            updateDb(state, payload)
        end
        {:ok, state}
    end

    def handle_event({_event, _payload}, state) do
        {:ok, state}
    end
end
