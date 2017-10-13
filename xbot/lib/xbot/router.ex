defmodule Xbot.Router do
    use Plug.Router

    plug :match
    plug CORSPlug
    plug :dispatch

    get "/:page" do
        send_resp(conn, 200, Xbot.ETS.paginate(page) |> Poison.encode!)
    end

    # catchall/404 route
    match _, do: conn |> send_resp(404, "Not Found")
end
