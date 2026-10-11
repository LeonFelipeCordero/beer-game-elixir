defmodule BeerGame.BoardsTest do
  use BeerGame.DataCase

  alias BeerGame.Boards
  import BeerGame.GameFixtures

  test "creates a named, running board and retrieves its players" do
    board = board_fixture()
    player = player_fixture(board)

    assert board.state == "running"
    refute board.full
    refute board.finished
    assert Boards.get_by_name(board.name).id == board.id
    assert Boards.get_by_name("missing-board") == nil
    assert [loaded_player] = Boards.get_board!(board.id).players
    assert loaded_player.id == player.id
  end

  test "requires a name and retains persisted values after invalid updates" do
    assert {:error, changeset} = Boards.create_board(%{})
    assert errors_on(changeset).name == ["can't be blank"]
    board = board_fixture()
    assert {:error, changeset} = Boards.update_board(board, %{name: nil})
    assert errors_on(changeset).name == ["can't be blank"]
    assert Boards.get_board!(board.id).name == board.name
    assert %Ecto.Changeset{valid?: true} = Boards.change_board(board)
  end

  test "updates and deletes boards" do
    Boards.subscribe("board")
    board = board_fixture()
    assert {:ok, updated} = Boards.update_board(board, %{full: true, finished: true})
    assert updated.full and updated.finished
    assert_receive {:board_updated, ^updated}
    assert {:ok, _} = Boards.delete_board(updated)
    assert_raise Ecto.NoResultsError, fn -> Boards.get_board!(board.id) end
  end

  test "initializes every role with its game inventory" do
    board = board_fixture()

    for {role, stock, weekly} <- [
          {"retailer", 8, 4},
          {"wholesaler", 120, 60},
          {"factory", 1200, 600}
        ] do
      player = player_fixture(board, role)
      assert player.board_id == board.id
      assert player.role == role
      assert player.stock == stock
      assert player.backlog == stock
      assert player.weekly_orders == weekly
      assert player.last_order == weekly
      refute player.cpu
    end

    assert length(Boards.list_players()) == 3
  end

  test "player updates and deletion are persisted and broadcast" do
    Boards.subscribe("players")
    player = player_fixture(board_fixture())
    assert_receive {:player_created, ^player}
    assert {:ok, updated} = Boards.update_player(player, %{stock: 25, weekly_orders: 7})
    assert_receive {:player_updated, ^updated}
    assert Boards.get_player(player.id).stock == 25
    assert {:error, changeset} = Boards.update_player(updated, %{stock: nil})
    assert errors_on(changeset).stock == ["can't be blank"]
    assert Boards.get_player(player.id).stock == 25
    assert {:ok, deleted} = Boards.delete_player_by_role(updated)
    assert_receive {:player_deleted, ^deleted}
    assert_raise Ecto.NoResultsError, fn -> Boards.get_player(player.id) end
  end

  test "leaving a full board makes the role available again" do
    board = board_fixture(%{full: true})
    player = player_fixture(board)
    Boards.subscribe("board")

    assert {:ok, _} = Boards.delete_player_by_role(player)
    refute Boards.get_board!(board.id).full
    assert_receive {:board_updated, updated}
    assert updated.id == board.id
    refute updated.full
  end

  test "delivery transfers stock and records the recipient's last order" do
    board = board_fixture()
    receiver = player_fixture(board)
    sender = player_fixture(board, "wholesaler")
    order = order_fixture(%{amount: 6})
    player_order_fixture(order, sender, "SENDING")
    player_order_fixture(order, receiver, "RECEIVING")

    assert {:ok, delivered} = BeerGame.Orders.deliver_order(order.id, sender.id)
    assert delivered.state == "DELIVERED"

    assert Boards.get_player(sender.id).stock == 114
    assert Boards.get_player(receiver.id).stock == 14
    assert Boards.get_player(receiver.id).last_order == 6
  end
end
