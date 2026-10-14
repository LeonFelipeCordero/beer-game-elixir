defmodule BeerGame.RunnersTest do
  use ExUnit.Case, async: true

  alias BeerGame.Scheduler
  alias Crontab.{CronExpression.Parser, DateChecker}

  test "the application supervises exactly the three thirty-second cron jobs" do
    assert Process.whereis(Scheduler)

    assert Scheduler.jobs() |> Enum.map(&elem(&1, 0)) |> Enum.sort() ==
             [:cpu_orders, :factory_production, :ordering_window]
  end

  for {name, runner, topic, command} <- [
        {:cpu_orders, BeerGame.OrderRunner, "cpu_orders", {:cpu_order_command}},
        {:ordering_window, BeerGame.StateRunner, "order_time", {:order_time_command, true}},
        {:factory_production, BeerGame.FactoryRunner, "factory", {:factory_deliver}}
      ] do
    test "#{name} runs every thirty seconds and broadcasts its existing command" do
      job = Scheduler.find_job(unquote(name))
      assert job.task == {unquote(runner), :run, []}
      assert job.schedule == Parser.parse!("*/30 * * * * *", true)
      assert job.state == :inactive

      for second <- 0..59 do
        date = NaiveDateTime.add(~N[2026-01-01 12:00:00], second)
        assert DateChecker.matches_date?(job.schedule, date) == second in [0, 30]
      end

      assert DateChecker.matches_date?(job.schedule, ~N[2026-01-01 12:01:00])
      Phoenix.PubSub.subscribe(BeerGame.PubSub, unquote(topic))
      assert Scheduler.run_job(unquote(name)) == :ok
      assert_receive unquote(Macro.escape(command)), 1_000
    end
  end
end
