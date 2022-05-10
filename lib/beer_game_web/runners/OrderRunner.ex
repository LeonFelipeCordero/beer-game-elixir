defmodule BeerGame.OrderRunner do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    :timer.send_interval(60_000, :work)
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    Phoenix.PubSub.broadcast!(BeerGame.PubSub, "cpu_orders", {:cpu_order_command})
    {:noreply, state}
  end
end
