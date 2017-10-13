defmodule Xbot.XSocket do
    @behaviour :cowboy_websocket_handler

    def init(_, _req, _opts) do
        {:upgrade, :protocol, :cowboy_websocket}
    end

    @timeout :infinity # terminate if no activity for one minute

    #Called on websocket connection initialization.
    def websocket_init(_type, req, _opts) do
        state = %{}
        # store pid
        Xbot.Registry.store(self())
        {:ok, req, state, @timeout}
    end

    # Handle 'ping' messages from the browser - reply
    def websocket_handle({:text, "ping"}, req, state) do
        {:reply, {:text, "pong"}, req, state}
    end

    # Handle other messages from the browser - don't reply
    def websocket_handle({:text, _message}, req, state) do
        {:ok, req, state}
    end

    # Format and forward elixir messages to client
    def websocket_info(message, req, state) do
        m = message |> Poison.encode!
        {:reply, {:text, m}, req, state}
    end

    # No matter why we terminate, remove all of this pids subscriptions
    def websocket_terminate(_reason, _req, _state) do
        Xbot.Registry.remove(self())
        :ok
    end

    def sendToAll(data) do
        Xbot.Registry.get |> Enum.map(fn pid -> send pid, data end)
        :ok
    end
end
