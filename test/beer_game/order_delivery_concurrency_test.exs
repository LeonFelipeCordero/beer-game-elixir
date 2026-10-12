defmodule BeerGame.OrderDeliveryConcurrencyTest do
  use ExUnit.Case, async: false

  import Ecto.Query
  import BeerGame.GameFixtures
  alias BeerGame.{Boards, Orders, Repo}
  alias BeerGame.Game.{Board, Order, Player, PlayerOrders}
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    {board, receiver, sender, orders} =
      Sandbox.unboxed_run(Repo, fn ->
        board = board_fixture()
        receiver = player_fixture(board)
        sender = player_fixture(board, "wholesaler")

        orders =
          for _ <- 1..2 do
            order = order_fixture(%{amount: 100})
            player_order_fixture(order, sender, "SENDING")
            player_order_fixture(order, receiver, "RECEIVING")
            order
          end

        {board, receiver, sender, orders}
      end)

    on_exit(fn ->
      Sandbox.unboxed_run(Repo, fn ->
        ids = Enum.map(orders, & &1.id)
        Repo.delete_all(from po in PlayerOrders, where: po.order_id in ^ids)
        Repo.delete_all(from o in Order, where: o.id in ^ids)
        Repo.delete_all(from p in Player, where: p.board_id == ^board.id)
        Repo.delete_all(from b in Board, where: b.id == ^board.id)
      end)
    end)

    {:ok, sender: sender, receiver: receiver, orders: orders}
  end

  test "concurrent deliveries of the same order transfer inventory only once", context do
    [order | _] = context.orders
    results = race_deliveries([order, order], context.sender.id)
    assert Enum.count(results, &match?({:ok, _}, &1)) == 1
    assert Enum.count(results, &match?({:error, _}, &1)) == 1
    assert_inventory(context)

    Sandbox.unboxed_run(Repo, fn ->
      assert Orders.get_order!(order.id).state == "DELIVERED"
    end)
  end

  test "different orders competing for the same stock cannot overdraw the sender", context do
    results = race_deliveries(context.orders, context.sender.id)
    assert Enum.count(results, &match?({:ok, _}, &1)) == 1
    assert Enum.count(results, &match?({:error, _}, &1)) == 1
    assert_inventory(context)

    Sandbox.unboxed_run(Repo, fn ->
      assert Enum.sort(Enum.map(context.orders, &Orders.get_order!(&1.id).state)) ==
               ["DELIVERED", "PENDING"]
    end)
  end

  test "production racing delivery preserves both stock changes", context do
    Sandbox.unboxed_run(Repo, fn ->
      Repo.update!(
        Ecto.Changeset.change(context.sender, role: "factory", stock: 1200, weekly_orders: 600)
      )
    end)

    [order | _] = context.orders

    results =
      race_actions([
        fn -> Boards.produce_stock(context.sender.id) end,
        fn -> Orders.deliver_order(order.id, context.sender.id) end
      ])

    assert Enum.all?(results, &match?({:ok, _}, &1))

    Sandbox.unboxed_run(Repo, fn ->
      assert Boards.get_player(context.sender.id).stock == 1700
      assert Boards.get_player(context.receiver.id).stock == 108
      assert Orders.get_order!(order.id).state == "DELIVERED"
    end)
  end

  test "CPU ordering waits for a concurrent quit and leaves no new order", context do
    Sandbox.unboxed_run(Repo, fn -> Orders.create_cpu_order_data(context.sender) end)
    parent = self()

    quit =
      Task.async(fn ->
        Sandbox.unboxed_run(Repo, fn ->
          Repo.transact(fn ->
            Repo.delete!(context.sender)
            send(parent, :player_deleted)

            receive do
              :commit -> {:ok, :deleted}
            end
          end)
        end)
      end)

    assert_receive :player_deleted, 5_000

    cpu =
      Task.async(fn ->
        Sandbox.unboxed_run(Repo, fn -> Orders.create_cpu_orders(context.sender) end)
      end)

    assert Task.yield(cpu, 100) == nil
    send(quit.pid, :commit)
    assert {:ok, :deleted} = Task.await(quit, 5_000)
    assert {:error, :player_not_found} = Task.await(cpu, 5_000)

    Sandbox.unboxed_run(Repo, fn ->
      assert Enum.sort(Enum.map(Orders.list_orders(), & &1.id)) ==
               Enum.sort(Enum.map(context.orders, & &1.id))
    end)
  end

  defp race_deliveries(orders, sender_id) do
    race_actions(
      Enum.map(orders, fn order -> fn -> Orders.deliver_order(order.id, sender_id) end end)
    )
  end

  defp race_actions(actions) do
    parent = self()

    tasks =
      Enum.map(actions, fn action ->
        Task.async(fn ->
          Sandbox.unboxed_run(Repo, fn ->
            send(parent, {:ready, self()})

            receive do
              :deliver -> action.()
            end
          end)
        end)
      end)

    Enum.each(tasks, fn task ->
      pid = task.pid
      assert_receive {:ready, ^pid}, 5_000
    end)

    Enum.each(tasks, &send(&1.pid, :deliver))
    Task.await_many(tasks, 10_000)
  end

  defp assert_inventory(context) do
    Sandbox.unboxed_run(Repo, fn ->
      assert Boards.get_player(context.sender.id).stock == 20
      assert Boards.get_player(context.receiver.id).stock == 108
      assert Boards.get_player(context.receiver.id).last_order == 100
    end)
  end
end
