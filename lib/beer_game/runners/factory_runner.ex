defmodule BeerGame.FactoryRunner do
  def run do
    Phoenix.PubSub.broadcast!(BeerGame.PubSub, "factory", {:factory_deliver})
  end
end
