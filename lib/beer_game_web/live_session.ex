defmodule BeerGameWeb.LiveSession do
  @moduledoc "Signed-cookie identity and server-side game state for LiveViews."

  @behaviour Plug

  alias BeerGame.LiveSessionStore

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    if Plug.Conn.get_session(conn, "live_session_id") do
      conn
    else
      Plug.Conn.put_session(
        conn,
        "live_session_id",
        Base.url_encode64(:crypto.strong_rand_bytes(32))
      )
    end
  end

  def get_session(%{"live_session_id" => id} = session) do
    Map.merge(session, LiveSessionStore.get(id))
  end

  def maybe_subscribe(socket, %{"live_session_id" => id}) do
    if Phoenix.LiveView.connected?(socket) do
      Phoenix.PubSub.subscribe(BeerGame.PubSub, "live_session:#{id}")
    end

    Phoenix.LiveView.put_private(socket, :live_session_id, id)
  end

  def put_session(%Phoenix.LiveView.Socket{} = socket, key, value) do
    LiveSessionStore.put(socket.private.live_session_id, to_string(key), value)
    socket
  end
end
