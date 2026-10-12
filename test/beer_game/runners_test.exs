defmodule BeerGame.RunnersTest do
  use ExUnit.Case, async: true

  for {runner, topic, command} <- [
        {BeerGame.OrderRunner, "cpu_orders", {:cpu_order_command}},
        {BeerGame.StateRunner, "order_time", {:order_time_command, true}},
        {BeerGame.FactoryRunner, "factory", {:factory_deliver}}
      ] do
    test "#{runner} broadcasts its work command and keeps running" do
      Phoenix.PubSub.subscribe(BeerGame.PubSub, unquote(topic))
      pid = start_supervised!(unquote(runner))
      send(pid, :work)
      assert_receive unquote(Macro.escape(command))
      assert :sys.get_state(pid) == %{}
    end
  end
end
