defmodule BeerGame.LiveSessionStore do
  @moduledoc "In-memory game sessions, serialized and expired after two days of inactivity."

  use GenServer

  @lifetime 48 * 60 * 60
  @cleanup_interval 60_000

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  def get(id), do: GenServer.call(__MODULE__, {:get, id})
  def put(id, key, value), do: GenServer.call(__MODULE__, {:put, id, key, value})

  @impl true
  def init(sessions) do
    Process.send_after(self(), :cleanup, @cleanup_interval)
    {:ok, sessions}
  end

  @impl true
  def handle_call({:get, id}, _from, sessions) do
    {data, sessions} = fetch(sessions, id)
    {:reply, data, sessions}
  end

  def handle_call({:put, id, key, value}, _from, sessions) do
    {data, sessions} = fetch(sessions, id)
    data = Map.put(data, key, value)
    sessions = Map.put(sessions, id, {data, now() + @lifetime})
    Phoenix.PubSub.broadcast(BeerGame.PubSub, "live_session:#{id}", {:live_session_updated, data})
    {:reply, :ok, sessions}
  end

  @impl true
  def handle_info(:cleanup, sessions) do
    cutoff = now()
    sessions = Map.reject(sessions, fn {_id, {_data, expiry}} -> expiry <= cutoff end)
    Process.send_after(self(), :cleanup, @cleanup_interval)
    {:noreply, sessions}
  end

  defp fetch(sessions, id) do
    case Map.get(sessions, id) do
      {data, expiry} ->
        if expiry > now() do
          {data, Map.put(sessions, id, {data, now() + @lifetime})}
        else
          {%{}, Map.delete(sessions, id)}
        end

      nil ->
        {%{}, sessions}
    end
  end

  defp now, do: System.monotonic_time(:second)
end
