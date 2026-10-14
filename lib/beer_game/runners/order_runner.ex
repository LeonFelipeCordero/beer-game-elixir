defmodule BeerGame.OrderRunner do
  def run do
    Phoenix.PubSub.broadcast!(BeerGame.PubSub, "cpu_orders", {:cpu_order_command})
  end
end
