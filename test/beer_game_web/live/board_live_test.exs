defmodule BeerGameWeb.BoardLiveTest do
  use BeerGameWeb.ConnCase

  import Phoenix.LiveViewTest
  import BeerGame.GameFixtures
  alias BeerGame.{Boards, Orders, Repo}
  alias BeerGame.Game.{CpuOrderData, Player}

  test "board index lists games, links to selection, and deletes a board", %{conn: conn} do
    board = board_fixture(%{state: "paused"})
    {:ok, index, _} = live(conn, ~p"/board")
    assert has_element?(index, "#board-#{board.id}", "paused")
    assert has_element?(index, "#board-#{board.id} a[href='/board/#{board.id}/player']")
    assert has_element?(index, "a[href='/board/new']", "New Board")
    index |> element("#board-#{board.id} button", "Delete") |> render_click()
    refute has_element?(index, "#board-#{board.id}")
    assert Boards.get_by_name(board.name) == nil
  end

  test "landing joins an existing board by name", %{conn: conn} do
    board = board_fixture()
    conn = get(conn, ~p"/")
    {:ok, landing, _} = live(conn)

    {:ok, selection, html} =
      landing
      |> form("form[phx-submit=join_board]", name: board.name)
      |> render_submit()
      |> follow_redirect(conn, ~p"/board/#{board}/player")

    assert html =~ board.name
    assert has_element?(selection, "[phx-value-role=retailer]")
    assert has_element?(selection, "[phx-value-role=wholesaler]")
    assert has_element?(selection, "[phx-value-role=factory]")
  end

  test "unknown board names leave the visitor on the landing page with an error", %{conn: conn} do
    conn = get(conn, ~p"/")
    {:ok, landing, _} = live(conn)

    html =
      landing
      |> form("form[phx-submit=join_board]", name: "missing-board")
      |> render_submit()

    assert html =~ "Board not found"
    assert has_element?(landing, "form[phx-submit=join_board]")
    assert Boards.get_by_name("missing-board") == nil
  end

  test "new board form persists the board and opens role selection", %{conn: conn} do
    name = "new-board-#{System.unique_integer([:positive])}"
    conn = get(conn, ~p"/board/new")
    {:ok, new_board, _} = live(conn)
    result = new_board |> form("form[phx-submit=create_board]", name: name) |> render_submit()
    board = Boards.get_by_name(name)
    assert board.state == "running"
    refute board.full
    {:ok, selection, html} = follow_redirect(result, conn, ~p"/board/#{board}/player")
    assert html =~ name
    assert has_element?(selection, "[phx-value-role=retailer]")
  end

  test "selection excludes taken roles and marks the board full after the final join", %{
    conn: conn
  } do
    board = board_fixture()
    player_fixture(board, "wholesaler")
    player_fixture(board, "factory")
    conn = get(conn, ~p"/board/#{board}/player")
    {:ok, selection, _} = live(conn)
    refute has_element?(selection, "[phx-value-role=wholesaler]")
    refute has_element?(selection, "[phx-value-role=factory]")

    {_conn, game, html} =
      selection
      |> element("[phx-value-role=retailer]")
      |> render_click()
      |> follow_game_redirect(conn, ~p"/board/#{board}")

    assert html =~ "Role retailer"
    assert Boards.get_board!(board.id).full
    assert has_element?(game, "input[name=amount][value='4']")
    retailer = Enum.find(Boards.get_board!(board.id).players, &(&1.role == "retailer"))
    assert Repo.get_by!(CpuOrderData, player_id: retailer.id).amount == 4
  end

  test "role and board persist across HTTP reload; abandon clears the session", %{conn: conn} do
    board = board_fixture()
    {conn, game} = join_game(conn, board, "retailer")
    player = hd(Boards.get_board!(board.id).players)

    {:ok, reloaded, html} = conn |> recycle() |> live(~p"/board/#{board}")
    assert html =~ board.name
    assert html =~ "Role retailer"
    assert has_element?(reloaded, "input[name=amount][value='4']")

    assert {:error, {:live_redirect, %{to: path}}} =
             conn |> recycle() |> live(~p"/board/#{board}/player")

    assert path == ~p"/board/#{board}"

    {_conn, _landing, html} =
      game
      |> element("button", "Quit Game")
      |> render_click()
      |> follow_game_redirect(conn, ~p"/")

    assert html =~ "Join Board"
    assert Repo.get(Player, player.id) == nil
    {:ok, selection, _} = conn |> recycle() |> live(~p"/board/#{board}/player")
    assert has_element?(selection, "[phx-value-role=retailer]")
  end

  test "weekly orders persist and create supplier/recipient associations", %{conn: conn} do
    board = board_fixture()
    wholesaler = player_fixture(board, "wholesaler")
    {conn, game} = join_game(conn, board, "retailer")
    refute has_element?(game, "form[phx-submit=create_order] input[type=submit]")
    send(game.pid, {:order_time_command, true})
    assert has_element?(game, "form[phx-submit=create_order] input[type=submit]")
    game |> form("form[phx-submit=create_order]", amount: "6") |> render_submit()
    refute has_element?(game, "form[phx-submit=create_order] input[type=submit]")

    assert [order] = Orders.list_orders()
    assert order.amount == 6
    assert order.type == "PLAYER_ORDER"
    retailer = Enum.find(Boards.get_board!(board.id).players, &(&1.role == "retailer"))
    assert retailer.weekly_orders == 6
    associations = Orders.get_player_orders(order.id)
    assert Enum.any?(associations, &(&1.player_id == retailer.id and &1.type == "RECEIVING"))
    assert Enum.any?(associations, &(&1.player_id == wholesaler.id and &1.type == "SENDING"))
    {:ok, reloaded, _} = conn |> recycle() |> live(~p"/board/#{board}")
    assert has_element?(reloaded, "input[name=amount][value='6']")
    refute has_element?(reloaded, "form[phx-submit=create_order] input[type=submit]")
  end

  test "delivery updates order status and both inventories", %{conn: conn} do
    board = board_fixture()
    retailer = player_fixture(board)
    {_conn, game} = join_game(conn, board, "wholesaler")
    wholesaler = Enum.find(Boards.get_board!(board.id).players, &(&1.role == "wholesaler"))
    order = order_fixture(%{amount: 6})
    player_order_fixture(order, retailer, "RECEIVING")
    player_order_fixture(order, wholesaler, "SENDING")
    selector = "button[phx-click=deliver_order][phx-value-order_id='#{order.id}']"
    assert has_element?(game, selector)
    game |> element(selector) |> render_click()
    assert Orders.get_order!(order.id).state == "DELIVERED"
    assert Boards.get_player(wholesaler.id).stock == 114
    assert Boards.get_player(retailer.id).stock == 14
    assert Boards.get_player(retailer.id).last_order == 6
    assert render(game) =~ "DELIVERED"
    refute has_element?(game, selector)
  end

  test "insufficient stock disables delivery", %{conn: conn} do
    board = board_fixture()
    {_conn, game} = join_game(conn, board, "retailer")
    retailer = hd(Boards.get_board!(board.id).players)
    order = order_fixture(%{amount: 9, type: "CPU_ORDER"})
    player_order_fixture(order, retailer, "SENDING")
    assert has_element?(game, "button[disabled]", "No Stock")
    refute has_element?(game, "button[phx-click=deliver_order]")
    assert Orders.get_order!(order.id).state == "PENDING"
    assert Boards.get_player(retailer.id).stock == 8
  end

  test "factory weekly production persists without placing a supplier order", %{conn: conn} do
    board = board_fixture()
    {conn, game} = join_game(conn, board, "factory")
    game |> form("form[phx-submit=create_order]", amount: "750") |> render_submit()
    factory = hd(Boards.get_board!(board.id).players)
    assert factory.weekly_orders == 750
    assert Orders.list_orders() == []
    {:ok, reloaded, _} = conn |> recycle() |> live(~p"/board/#{board}")
    assert has_element?(reloaded, "input[name=amount][value='750']")
  end

  test "factory delivery adds weekly production to stock", %{conn: conn} do
    board = board_fixture()
    {_conn, game} = join_game(conn, board, "factory")
    factory = hd(Boards.get_board!(board.id).players)
    send(game.pid, {:factory_deliver})
    render(game)
    assert Boards.get_player(factory.id).stock == 1800
    assert render(game) =~ "1800"
    assert has_element?(game, "label", "Weekly production")
  end

  test "a supplier joining an already mounted retailer is used for the next order", %{conn: conn} do
    board = board_fixture()
    {_conn, game} = join_game(conn, board, "retailer")
    supplier = player_fixture(board, "wholesaler")
    send(game.pid, {:order_time_command, true})
    game |> form("form[phx-submit=create_order]", amount: "6") |> render_submit()

    assert [order] = Orders.list_orders()
    retailer = Enum.find(Boards.get_board!(board.id).players, &(&1.role == "retailer"))

    assert Enum.sort(Enum.map(Orders.get_player_orders(order.id), &{&1.player_id, &1.type})) ==
             Enum.sort([{retailer.id, "RECEIVING"}, {supplier.id, "SENDING"}])
  end

  test "a supplier leaving does not insert an orphan order or consume the order turn", %{
    conn: conn
  } do
    board = board_fixture()
    supplier = player_fixture(board, "wholesaler")
    {_conn, game} = join_game(conn, board, "retailer")
    Boards.delete_player_by_role(supplier)
    send(game.pid, {:order_time_command, true})
    game |> form("form[phx-submit=create_order]", amount: "6") |> render_submit()

    assert Orders.list_orders() == []
    assert Repo.all(BeerGame.Game.PlayerOrders) == []
    assert has_element?(game, "form[phx-submit=create_order] input[type=submit]")
    retailer = Enum.find(Boards.get_board!(board.id).players, &(&1.role == "retailer"))
    assert retailer.weekly_orders == 4
    assert Process.alive?(game.pid)
  end

  test "foreign board role events do not change available roles", %{conn: conn} do
    board = board_fixture()
    player_fixture(board, "retailer")
    {:ok, selection, _} = live(conn, ~p"/board/#{board}/player")
    foreign = player_fixture(board_fixture(), "wholesaler")
    render(selection)
    assert has_element?(selection, "[phx-value-role=wholesaler]")
    refute has_element?(selection, "[phx-value-role=retailer]")

    foreign_retailer = player_fixture(Boards.get_board!(foreign.board_id), "retailer")
    Boards.delete_player_by_role(foreign_retailer)
    render(selection)
    assert has_element?(selection, "[phx-value-role=wholesaler]")
    refute has_element?(selection, "[phx-value-role=retailer]")
  end

  test "a spectator sees the final join make the board full and leaving reopen it", %{conn: conn} do
    board = board_fixture()
    player_fixture(board, "wholesaler")
    player_fixture(board, "factory")
    {:ok, spectator, _} = live(conn, ~p"/board/#{board}/player")
    {_other_conn, game} = join_game(build_conn(), board, "retailer")
    assert render(spectator) =~ "The board is full"
    refute has_element?(spectator, "[phx-value-role=retailer]")

    game |> element("button", "Quit Game") |> render_click()
    refute render(spectator) =~ "The board is full"
    assert has_element?(spectator, "[phx-value-role=retailer]")
  end

  test "board updates refresh only the matching selection", %{conn: conn} do
    board = board_fixture()
    {:ok, selection, _} = live(conn, ~p"/board/#{board}/player")
    foreign = board_fixture()
    Boards.update_board(foreign, %{name: "foreign-rename", full: true})
    html = render(selection)
    assert html =~ board.name
    refute html =~ "foreign-rename"
    refute html =~ "The board is full"
    Boards.update_board(board, %{name: "current-rename"})
    assert render(selection) =~ "current-rename"
  end

  test "forged recipient delivery events cannot change inventories or order state", %{conn: conn} do
    board = board_fixture()
    sender = player_fixture(board, "wholesaler")
    {_conn, game} = join_game(conn, board, "retailer")
    receiver = Enum.find(Boards.get_board!(board.id).players, &(&1.role == "retailer"))
    order = order_fixture(%{amount: 6})
    player_order_fixture(order, receiver, "RECEIVING")
    player_order_fixture(order, sender, "SENDING")

    render_click(game, "deliver_order", %{"order_id" => to_string(order.id)})
    assert Orders.get_order!(order.id).state == "PENDING"
    assert Boards.get_player(sender.id).stock == 120
    assert Boards.get_player(receiver.id).stock == 8
    assert Process.alive?(game.pid)
  end

  test "forged insufficient-stock and repeated delivery events cannot deliver twice", %{
    conn: conn
  } do
    board = board_fixture()
    {_conn, game} = join_game(conn, board, "retailer")
    sender = hd(Boards.get_board!(board.id).players)
    large = order_fixture(%{amount: 9, type: "CPU_ORDER"})
    player_order_fixture(large, sender, "SENDING")
    render_click(game, "deliver_order", %{"order_id" => to_string(large.id)})
    assert Orders.get_order!(large.id).state == "PENDING"
    assert Boards.get_player(sender.id).stock == 8

    small = order_fixture(%{amount: 4, type: "CPU_ORDER"})
    player_order_fixture(small, sender, "SENDING")
    for _ <- 1..2, do: render_click(game, "deliver_order", %{"order_id" => to_string(small.id)})
    assert Orders.get_order!(small.id).state == "DELIVERED"
    assert Boards.get_player(sender.id).stock == 4
    assert Process.alive?(game.pid)
  end

  test "queued session snapshots cannot restore stale order permission", %{conn: conn} do
    board = board_fixture()
    {conn, game} = join_game(conn, board, "retailer")
    id = get_session(conn, "live_session_id")
    current = BeerGame.LiveSessionStore.get(id)
    BeerGame.LiveSessionStore.put(id, "order_time", false)
    send(game.pid, {:live_session_updated, Map.put(current, "order_time", true)})
    refute has_element?(game, "form[phx-submit=create_order] input[type=submit]")
    assert Process.alive?(game.pid)
  end

  test "reload with a deleted player or board redirects rather than raising", %{conn: conn} do
    board = board_fixture()
    {conn, _game} = join_game(conn, board, "retailer")
    player = hd(Boards.get_board!(board.id).players)
    Repo.delete!(player)
    assert {:error, {_kind, %{to: "/"}}} = conn |> recycle() |> live(~p"/board/#{board}")
    Repo.delete!(board)
    assert {:error, {_kind, %{to: "/"}}} = conn |> recycle() |> live(~p"/board/#{board}")
  end

  test "a queued CPU command after the player's deletion redirects without crashing", %{
    conn: conn
  } do
    board = board_fixture()
    {_conn, game} = join_game(conn, board, "retailer")
    player = hd(Boards.get_board!(board.id).players)
    Repo.delete!(player)
    send(game.pid, {:cpu_order_command})
    assert_redirect(game, "/")
    assert Orders.list_orders() == []
  end

  defp join_game(conn, board, role) do
    conn = get(conn, ~p"/board/#{board}/player")
    {:ok, selection, _} = live(conn)

    {conn, game, _} =
      selection
      |> element("[phx-value-role='#{role}']")
      |> render_click()
      |> follow_game_redirect(conn, ~p"/board/#{board}")

    {conn, game}
  end

  defp follow_game_redirect(result, conn, path) do
    case follow_redirect(result, conn, path) do
      {:ok, %Plug.Conn{} = redirected_conn} ->
        {:ok, game, html} = live(redirected_conn)
        {redirected_conn, game, html}

      {:ok, game, html} ->
        {conn, game, html}
    end
  end
end
