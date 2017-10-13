defmodule Xbot.Registry do
    use GenServer

    def start_link do
        GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    end

    def init(:ok) do
        {:ok, []}
    end

    def store(pid) when is_pid(pid) do
        GenServer.call(__MODULE__, {:store, pid})
    end

    def remove(pid) when is_pid(pid) do
        GenServer.call(__MODULE__, {:remove, pid})
    end

    def get do
        GenServer.call(__MODULE__, {:get})
    end

    def handle_call({:store, pid}, _from, procs) do
        {:reply, :ok, procs ++ [pid]}
    end

    def handle_call({:remove, pid}, _from, procs) do
        {:reply, :ok, List.delete(procs, pid)}
    end

    def handle_call({:get}, _from, procs) do
        {:reply, procs, procs}
    end

end
