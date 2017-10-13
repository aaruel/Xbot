defmodule Xbot.Application do
    # See http://elixir-lang.org/docs/stable/elixir/Application.html
    # for more information on OTP Applications
    @moduledoc false

    use Application
    require Logger

    def start(_type, _args) do
        import Supervisor.Spec, warn: false

        port = Application.get_env(:xbot, :connectionport)
        token = Application.get_env(:xbot, :token)

        dispatch = [
            {
                :_, [
                    {"/ws", Xbot.XSocket, []},
                    {:_, Plug.Adapters.Cowboy.Handler, {Xbot.Router, []}}
                ]
            }
        ]

        # Define workers and child supervisors to be supervised
        children = [
            supervisor(DiscordEx.Client, [%{token: token, handler: Xbot.Bot}]),
            Plug.Adapters.Cowboy.child_spec(:http, Xbot.Router, [], dispatch: dispatch, port: port),
            worker(Xbot.ETS, []),
            worker(Xbot.Registry, [])
        ]

        Logger.info "Monitoring on localhost:#{port}"

        # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
        # for other strategies and supported options
        opts = [strategy: :one_for_one, name: Xbot.Supervisor]
        Supervisor.start_link(children, opts)
    end
end
