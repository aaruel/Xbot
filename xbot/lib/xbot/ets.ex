defmodule Xbot.ETS do
    use GenServer

    def start_link do
        GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    end

    def init(:ok) do
        {:ok, PersistentEts.new(:db, "leaderboard.tab", [:named_table])}
    end

    def find(name) do
        case :ets.lookup(:db, name) do
            [{^name, items}] -> {:ok, items}
            [] -> :error
        end
    end

    def findall do
        :ets.match(:db, {:"$1", :"$2", :"$3", :"$4", :"$5"})
    end

    def paginate(page) do
        page = String.to_integer(page)

        getScores = fn d ->
            %{"emoji" => pre, "count" => count} = d
            %{"name" => name} = pre
            case name do
                "upvote" -> count
                "downvote" -> -count
                _ -> 0
            end
        end

        sorter = fn([_,_,_,_,a],[_,_,_,_,b]) ->
            ascore = a |> Enum.map(getScores) |> Enum.sum
            bscore = b |> Enum.map(getScores) |> Enum.sum
            ascore >= bscore
        end
        left = 10 * (page - 1)
        right = left + 9
        findall() |> Enum.sort(sorter) |> Enum.slice(left..right)
    end

    def apply(name, item) do
        GenServer.call(__MODULE__, {:apply, name, item})
    end

    def apply(tuple) when is_tuple(tuple) do
        GenServer.call(__MODULE__, {:apply, tuple})
    end

    def handle_call({:apply, name, item}, _from, table) do
        case :ets.insert(table, {name, item}) do
            true -> {:reply, item, table}
            _ -> {:reply, :error, table}
        end
    end

    def handle_call({:apply, tuple}, _from, table) do
        case :ets.insert(table, tuple) do
            true -> {:reply, tuple, table}
            _ -> {:reply, :error, table}
        end
    end
end
