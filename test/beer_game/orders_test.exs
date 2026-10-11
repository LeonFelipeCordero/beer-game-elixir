defmodule BeerGame.OrdersTest do
  use BeerGame.DataCase

  alias BeerGame.{Boards, Orders}
  alias BeerGame.Game.CpuOrderData
  import BeerGame.GameFixtures

  test "lists, retrieves, updates, and deletes orders" do
    Orders.subscribe("orders")
    order = order_fixture()
    assert Orders.list_orders() == [order]
    assert Orders.get_order!(order.id) == order
    assert %Ecto.Changeset{valid?: true} = Orders.change_order(order)
    assert {:ok, updated} = Orders.update_order(order, %{amount: 9, state: "DELIVERED"})
    assert updated.amount == 9
    assert updated.state == "DELIVERED"
    assert_receive {:order_updated, ^updated}
    assert {:ok, _} = Orders.delete_order(updated)
    assert_raise Ecto.NoResultsError, fn -> Orders.get_order!(order.id) end
  end

  test "rejects missing and non-integer quantities without overwriting an order" do
    assert {:error, changeset} = Orders.create_order(%{})
    assert errors_on(changeset) == %{amount: ["can't be blank"], type: ["can't be blank"]}
    order = order_fixture()
    assert {:error, changeset} = Orders.update_order(order, %{amount: "not a number"})
    assert errors_on(changeset).amount == ["is invalid"]
    assert Orders.get_order!(order.id) == order
  end

  test "player orders preload both sides and broadcast their creation" do
    Orders.subscribe("player_orders")
    player = player_fixture(board_fixture())
    order = order_fixture()
    association = player_order_fixture(order, player, "RECEIVING")
    assert_receive {:order_created, ^association}
    assert [loaded] = Orders.get_player_orders(order.id)
    assert loaded.player.id == player.id
    assert loaded.order == order
    assert loaded.type == "RECEIVING"
    assert Boards.get_player(player.id).orders == [order]
    assert {:error, changeset} = Orders.create_player_order(%{}, order, player)
    assert errors_on(changeset).type == ["can't be blank"]
  end

  test "retailers and wholesalers place orders with their upstream supplier" do
    board = board_fixture()
    retailer = player_fixture(board)
    wholesaler = player_fixture(board, "wholesaler")
    factory = player_fixture(board, "factory")
    board = Boards.get_board!(board.id)

    for {receiver, sender} <- [{retailer, wholesaler}, {wholesaler, factory}] do
      socket = %Phoenix.LiveView.Socket{assigns: %{player: receiver, board: board}}
      order = Orders.create_orders(socket, "7")
      assert order.amount == 7
      assert order.type == "PLAYER_ORDER"
      associations = Orders.get_player_orders(order.id)
      assert Enum.any?(associations, &(&1.player_id == receiver.id and &1.type == "RECEIVING"))
      assert Enum.any?(associations, &(&1.player_id == sender.id and &1.type == "SENDING"))
    end
  end

  test "ordering uses current suppliers rather than a stale board snapshot" do
    board = board_fixture()
    retailer = player_fixture(board)
    stale_board = Boards.get_board!(board.id)
    supplier = player_fixture(board, "wholesaler")
    socket = %Phoenix.LiveView.Socket{assigns: %{player: retailer, board: stale_board}}

    order = Orders.create_orders(socket, "6")
    assert order.amount == 6

    assert Enum.sort(Enum.map(Orders.get_player_orders(order.id), &{&1.player_id, &1.type})) ==
             Enum.sort([{retailer.id, "RECEIVING"}, {supplier.id, "SENDING"}])
  end

  test "a departed supplier leaves no order or association behind" do
    board = board_fixture()
    retailer = player_fixture(board)
    supplier = player_fixture(board, "wholesaler")

    socket = %Phoenix.LiveView.Socket{
      assigns: %{player: retailer, board: Boards.get_board!(board.id)}
    }

    Boards.delete_player_by_role(supplier)

    assert {:error, _} = Orders.create_orders(socket, "6")
    assert Orders.list_orders() == []
    assert Repo.all(BeerGame.Game.PlayerOrders) == []
  end

  test "CPU ordering without demand data returns an error without inserts" do
    player = player_fixture(board_fixture())
    assert {:error, _} = Orders.create_cpu_orders(player)
    assert Orders.list_orders() == []
    assert Repo.all(BeerGame.Game.PlayerOrders) == []
  end

  test "only the sending player can deliver, and a delivered order cannot be delivered twice" do
    {order, sender, receiver} = delivery_fixture()
    foreign_player = player_fixture(board_fixture(), "wholesaler")
    Orders.subscribe("orders")
    Boards.subscribe("players")

    for unauthorized <- [receiver, foreign_player] do
      assert {:error, _} = Orders.deliver_order(order.id, unauthorized.id)
      assert Orders.get_order!(order.id).state == "PENDING"
      assert Boards.get_player(sender.id).stock == 120
      assert Boards.get_player(receiver.id).stock == 8
      refute_receive {:order_updated, _}, 0
      refute_receive {:player_updated, _}, 0
    end

    assert {:ok, delivered} = Orders.deliver_order(order.id, sender.id)
    assert delivered.state == "DELIVERED"
    assert_receive {:order_updated, ^delivered}
    assert_receive {:player_updated, %{id: sender_id, stock: 114}}
    assert sender_id == sender.id
    assert_receive {:player_updated, %{id: receiver_id, stock: 14, last_order: 6}}
    assert receiver_id == receiver.id
    assert {:error, _} = Orders.deliver_order(order.id, sender.id)
    assert Boards.get_player(sender.id).stock == 114
    assert Boards.get_player(receiver.id).stock == 14
    refute_receive {:order_updated, _}, 0
    refute_receive {:player_updated, _}, 0
  end

  test "insufficient stock rolls back both inventories and order state" do
    {order, sender, receiver} = delivery_fixture()
    assert {:ok, _} = Boards.update_player(sender, %{stock: 5})
    assert {:error, _} = Orders.deliver_order(order.id, sender.id)
    assert Orders.get_order!(order.id).state == "PENDING"
    assert Boards.get_player(sender.id).stock == 5
    assert Boards.get_player(receiver.id).stock == 8
    assert Boards.get_player(receiver.id).last_order == 4
  end

  test "a nonexistent order is a delivery error rather than an exception" do
    sender = player_fixture(board_fixture())
    assert {:error, _} = Orders.deliver_order(0, sender.id)
  end

  defp delivery_fixture do
    board = board_fixture()
    receiver = player_fixture(board)
    sender = player_fixture(board, "wholesaler")
    order = order_fixture(%{amount: 6})
    player_order_fixture(order, sender, "SENDING")
    player_order_fixture(order, receiver, "RECEIVING")
    {order, sender, receiver}
  end

  test "CPU demand starts at weekly orders and grows on subsequent rounds" do
    player = player_fixture(board_fixture())
    assert {:ok, data} = Orders.create_cpu_order_data(player)
    assert data.amount == 4
    assert {:ok, updated} = Orders.create_cpu_orders(player)
    assert updated.amount == 10
    assert [order] = Orders.list_orders()
    assert order.amount == 4
    assert order.type == "CPU_ORDER"
    assert [association] = Orders.get_player_orders(order.id)
    assert association.player_id == player.id
    assert association.type == "SENDING"
    assert {:ok, updated} = Orders.create_cpu_orders(player)
    assert updated.amount == 12
    assert Repo.get!(CpuOrderData, data.id).amount == 12
    assert Enum.sort(Enum.map(Orders.list_orders(), & &1.amount)) == [4, 10]
  end
end
