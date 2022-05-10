defmodule BeerGame.GameTest do
  use BeerGame.DataCase

  alias BeerGame.Game

  describe "player" do
    alias BeerGame.Game.Player

    import BeerGame.GameFixtures

    @invalid_attrs %{
      backlog: nil,
      lastOrder: nil,
      name: nil,
      role: nil,
      stock: nil,
      weeklyOrders: nil
    }

    test "list_player/0 returns all player" do
      player = player_fixture()
      assert Game.list_player() == [player]
    end

    test "get_player!/1 returns the player with given id" do
      player = player_fixture()
      assert Game.get_player!(player.id) == player
    end

    test "create_player/1 with valid data creates a player" do
      valid_attrs = %{
        backlog: "some backlog",
        lastOrder: "some lastOrder",
        name: "some name",
        role: "some role",
        stock: "some stock",
        weeklyOrders: "some weeklyOrders"
      }

      assert {:ok, %Player{} = player} = Game.create_player(valid_attrs)
      assert player.backlog == "some backlog"
      assert player.lastOrder == "some lastOrder"
      assert player.name == "some name"
      assert player.role == "some role"
      assert player.stock == "some stock"
      assert player.weeklyOrders == "some weeklyOrders"
    end

    test "create_player/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Game.create_player(@invalid_attrs)
    end

    test "update_player/2 with valid data updates the player" do
      player = player_fixture()

      update_attrs = %{
        backlog: "some updated backlog",
        lastOrder: "some updated lastOrder",
        name: "some updated name",
        role: "some updated role",
        stock: "some updated stock",
        weeklyOrders: "some updated weeklyOrders"
      }

      assert {:ok, %Player{} = player} = Game.update_player(player, update_attrs)
      assert player.backlog == "some updated backlog"
      assert player.lastOrder == "some updated lastOrder"
      assert player.name == "some updated name"
      assert player.role == "some updated role"
      assert player.stock == "some updated stock"
      assert player.weeklyOrders == "some updated weeklyOrders"
    end

    test "update_player/2 with invalid data returns error changeset" do
      player = player_fixture()
      assert {:error, %Ecto.Changeset{}} = Game.update_player(player, @invalid_attrs)
      assert player == Game.get_player!(player.id)
    end

    test "delete_player/1 deletes the player" do
      player = player_fixture()
      assert {:ok, %Player{}} = Game.delete_player(player)
      assert_raise Ecto.NoResultsError, fn -> Game.get_player!(player.id) end
    end

    test "change_player/1 returns a player changeset" do
      player = player_fixture()
      assert %Ecto.Changeset{} = Game.change_player(player)
    end
  end

  describe "board" do
    alias BeerGame.Game.Board

    import BeerGame.GameFixtures

    @invalid_attrs %{full: nil, state: nil}

    test "list_board/0 returns all board" do
      board = board_fixture()
      assert Game.list_board() == [board]
    end

    test "get_board!/1 returns the board with given id" do
      board = board_fixture()
      assert Game.get_board!(board.id) == board
    end

    test "create_board/1 with valid data creates a board" do
      valid_attrs = %{full: true, state: "some state"}

      assert {:ok, %Board{} = board} = Game.create_board(valid_attrs)
      assert board.full == true
      assert board.state == "some state"
    end

    test "create_board/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Game.create_board(@invalid_attrs)
    end

    test "update_board/2 with valid data updates the board" do
      board = board_fixture()
      update_attrs = %{full: false, state: "some updated state"}

      assert {:ok, %Board{} = board} = Game.update_board(board, update_attrs)
      assert board.full == false
      assert board.state == "some updated state"
    end

    test "update_board/2 with invalid data returns error changeset" do
      board = board_fixture()
      assert {:error, %Ecto.Changeset{}} = Game.update_board(board, @invalid_attrs)
      assert board == Game.get_board!(board.id)
    end

    test "delete_board/1 deletes the board" do
      board = board_fixture()
      assert {:ok, %Board{}} = Game.delete_board(board)
      assert_raise Ecto.NoResultsError, fn -> Game.get_board!(board.id) end
    end

    test "change_board/1 returns a board changeset" do
      board = board_fixture()
      assert %Ecto.Changeset{} = Game.change_board(board)
    end
  end

  describe "retailer_orders" do
    alias BeerGame.Game.RetailerOrder

    import BeerGame.GameFixtures

    @invalid_attrs %{amount: nil, state: nil}

    test "list_retailer_orders/0 returns all retailer_orders" do
      retailer_order = retailer_order_fixture()
      assert Game.list_retailer_orders() == [retailer_order]
    end

    test "get_retailer_order!/1 returns the retailer_order with given id" do
      retailer_order = retailer_order_fixture()
      assert Game.get_retailer_order!(retailer_order.id) == retailer_order
    end

    test "create_retailer_order/1 with valid data creates a retailer_order" do
      valid_attrs = %{amount: 42, state: true}

      assert {:ok, %RetailerOrder{} = retailer_order} = Game.create_retailer_order(valid_attrs)
      assert retailer_order.amount == 42
      assert retailer_order.state == true
    end

    test "create_retailer_order/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Game.create_retailer_order(@invalid_attrs)
    end

    test "update_retailer_order/2 with valid data updates the retailer_order" do
      retailer_order = retailer_order_fixture()
      update_attrs = %{amount: 43, state: false}

      assert {:ok, %RetailerOrder{} = retailer_order} = Game.update_retailer_order(retailer_order, update_attrs)
      assert retailer_order.amount == 43
      assert retailer_order.state == false
    end

    test "update_retailer_order/2 with invalid data returns error changeset" do
      retailer_order = retailer_order_fixture()
      assert {:error, %Ecto.Changeset{}} = Game.update_retailer_order(retailer_order, @invalid_attrs)
      assert retailer_order == Game.get_retailer_order!(retailer_order.id)
    end

    test "delete_retailer_order/1 deletes the retailer_order" do
      retailer_order = retailer_order_fixture()
      assert {:ok, %RetailerOrder{}} = Game.delete_retailer_order(retailer_order)
      assert_raise Ecto.NoResultsError, fn -> Game.get_retailer_order!(retailer_order.id) end
    end

    test "change_retailer_order/1 returns a retailer_order changeset" do
      retailer_order = retailer_order_fixture()
      assert %Ecto.Changeset{} = Game.change_retailer_order(retailer_order)
    end
  end

  describe "wholesaler_orders" do
    alias BeerGame.Game.WholesalerOrder

    import BeerGame.GameFixtures

    @invalid_attrs %{amount: nil, state: nil}

    test "list_wholesaler_orders/0 returns all wholesaler_orders" do
      wholesaler_order = wholesaler_order_fixture()
      assert Game.list_wholesaler_orders() == [wholesaler_order]
    end

    test "get_wholesaler_order!/1 returns the wholesaler_order with given id" do
      wholesaler_order = wholesaler_order_fixture()
      assert Game.get_wholesaler_order!(wholesaler_order.id) == wholesaler_order
    end

    test "create_wholesaler_order/1 with valid data creates a wholesaler_order" do
      valid_attrs = %{amount: 42, state: "some state"}

      assert {:ok, %WholesalerOrder{} = wholesaler_order} = Game.create_wholesaler_order(valid_attrs)
      assert wholesaler_order.amount == 42
      assert wholesaler_order.state == "some state"
    end

    test "create_wholesaler_order/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Game.create_wholesaler_order(@invalid_attrs)
    end

    test "update_wholesaler_order/2 with valid data updates the wholesaler_order" do
      wholesaler_order = wholesaler_order_fixture()
      update_attrs = %{amount: 43, state: "some updated state"}

      assert {:ok, %WholesalerOrder{} = wholesaler_order} = Game.update_wholesaler_order(wholesaler_order, update_attrs)
      assert wholesaler_order.amount == 43
      assert wholesaler_order.state == "some updated state"
    end

    test "update_wholesaler_order/2 with invalid data returns error changeset" do
      wholesaler_order = wholesaler_order_fixture()
      assert {:error, %Ecto.Changeset{}} = Game.update_wholesaler_order(wholesaler_order, @invalid_attrs)
      assert wholesaler_order == Game.get_wholesaler_order!(wholesaler_order.id)
    end

    test "delete_wholesaler_order/1 deletes the wholesaler_order" do
      wholesaler_order = wholesaler_order_fixture()
      assert {:ok, %WholesalerOrder{}} = Game.delete_wholesaler_order(wholesaler_order)
      assert_raise Ecto.NoResultsError, fn -> Game.get_wholesaler_order!(wholesaler_order.id) end
    end

    test "change_wholesaler_order/1 returns a wholesaler_order changeset" do
      wholesaler_order = wholesaler_order_fixture()
      assert %Ecto.Changeset{} = Game.change_wholesaler_order(wholesaler_order)
    end
  end

  describe "factory_orders" do
    alias BeerGame.Game.FactoryOrder

    import BeerGame.GameFixtures

    @invalid_attrs %{amount: nil, state: nil}

    test "list_factory_orders/0 returns all factory_orders" do
      factory_order = factory_order_fixture()
      assert Game.list_factory_orders() == [factory_order]
    end

    test "get_factory_order!/1 returns the factory_order with given id" do
      factory_order = factory_order_fixture()
      assert Game.get_factory_order!(factory_order.id) == factory_order
    end

    test "create_factory_order/1 with valid data creates a factory_order" do
      valid_attrs = %{amount: 42, state: "some state"}

      assert {:ok, %FactoryOrder{} = factory_order} = Game.create_factory_order(valid_attrs)
      assert factory_order.amount == 42
      assert factory_order.state == "some state"
    end

    test "create_factory_order/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Game.create_factory_order(@invalid_attrs)
    end

    test "update_factory_order/2 with valid data updates the factory_order" do
      factory_order = factory_order_fixture()
      update_attrs = %{amount: 43, state: "some updated state"}

      assert {:ok, %FactoryOrder{} = factory_order} = Game.update_factory_order(factory_order, update_attrs)
      assert factory_order.amount == 43
      assert factory_order.state == "some updated state"
    end

    test "update_factory_order/2 with invalid data returns error changeset" do
      factory_order = factory_order_fixture()
      assert {:error, %Ecto.Changeset{}} = Game.update_factory_order(factory_order, @invalid_attrs)
      assert factory_order == Game.get_factory_order!(factory_order.id)
    end

    test "delete_factory_order/1 deletes the factory_order" do
      factory_order = factory_order_fixture()
      assert {:ok, %FactoryOrder{}} = Game.delete_factory_order(factory_order)
      assert_raise Ecto.NoResultsError, fn -> Game.get_factory_order!(factory_order.id) end
    end

    test "change_factory_order/1 returns a factory_order changeset" do
      factory_order = factory_order_fixture()
      assert %Ecto.Changeset{} = Game.change_factory_order(factory_order)
    end
  end

  describe "orders" do
    alias BeerGame.Game.Order

    import BeerGame.GameFixtures

    @invalid_attrs %{amount: nil, contrapart_id: nil, state: nil}

    test "list_orders/0 returns all orders" do
      order = order_fixture()
      assert Game.list_orders() == [order]
    end

    test "get_order!/1 returns the order with given id" do
      order = order_fixture()
      assert Game.get_order!(order.id) == order
    end

    test "create_order/1 with valid data creates a order" do
      valid_attrs = %{amount: 42, contrapart_id: "some contrapart_id", state: "some state"}

      assert {:ok, %Order{} = order} = Game.create_order(valid_attrs)
      assert order.amount == 42
      assert order.contrapart_id == "some contrapart_id"
      assert order.state == "some state"
    end

    test "create_order/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Game.create_order(@invalid_attrs)
    end

    test "update_order/2 with valid data updates the order" do
      order = order_fixture()
      update_attrs = %{amount: 43, contrapart_id: "some updated contrapart_id", state: "some updated state"}

      assert {:ok, %Order{} = order} = Game.update_order(order, update_attrs)
      assert order.amount == 43
      assert order.contrapart_id == "some updated contrapart_id"
      assert order.state == "some updated state"
    end

    test "update_order/2 with invalid data returns error changeset" do
      order = order_fixture()
      assert {:error, %Ecto.Changeset{}} = Game.update_order(order, @invalid_attrs)
      assert order == Game.get_order!(order.id)
    end

    test "delete_order/1 deletes the order" do
      order = order_fixture()
      assert {:ok, %Order{}} = Game.delete_order(order)
      assert_raise Ecto.NoResultsError, fn -> Game.get_order!(order.id) end
    end

    test "change_order/1 returns a order changeset" do
      order = order_fixture()
      assert %Ecto.Changeset{} = Game.change_order(order)
    end
  end
end
