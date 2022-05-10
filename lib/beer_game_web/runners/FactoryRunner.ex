defmodule BeerGame.FactoryRunner do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    :timer.send_interval(120_000, :work)
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    Phoenix.PubSub.broadcast!(BeerGame.PubSub, "factory", {:factory_deliver})
    {:noreply, state}
  end
end
