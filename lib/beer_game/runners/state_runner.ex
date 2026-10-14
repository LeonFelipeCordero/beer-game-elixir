defmodule BeerGame.StateRunner do
  def run do
    Phoenix.PubSub.broadcast!(BeerGame.PubSub, "order_time", {:order_time_command, true})
  end
end
