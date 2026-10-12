defmodule BeerGameWeb.OrderRenderingTest do
  use BeerGameWeb.ConnCase

  import Phoenix.LiveViewTest
  import BeerGame.GameFixtures
  alias BeerGame.{Boards, LiveSessionStore, Orders}
  alias BeerGameWeb.BoardLive.Show

  test "a session refresh before a queued creation event keeps one outgoing order" do
    board = board_fixture()
    player = player_fixture(board)
    {:ok, _data} = Orders.create_cpu_order_data(player)
    id = "order-rendering-#{System.unique_integer([:positive])}"
    LiveSessionStore.put(id, "board", board)
    LiveSessionStore.put(id, "player", player)

    socket = %Phoenix.LiveView.Socket{
      transport_pid: self(),
      assigns: %{__changed__: %{}},
      private: %{}
    }

    {:ok, socket} = Show.mount(%{}, %{"live_session_id" => id}, socket)
    {:noreply, socket} = Show.handle_info({:order_time_command, true}, socket)
    {:noreply, socket} = Show.handle_info({:cpu_order_command}, socket)
    assert_receive {:live_session_updated, _session} = refresh
    assert_receive {:order_created, _association} = created
    {:noreply, socket} = Show.handle_info(refresh, socket)
    {:noreply, socket} = Show.handle_info(created, socket)

    assert [order] = Orders.list_orders()
    assert Enum.map(socket.assigns.sending_orders, & &1.id) == [order.id]
  end

  test "replayed creation events do not duplicate mounted or delivered rows", %{conn: conn} do
    board = board_fixture()
    {conn, game, player} = join_factory(conn, board)
    order = order_fixture(%{amount: 4, type: "CPU_ORDER"})
    association = player_order_fixture(order, player, "SENDING")
    render(game)
    {:ok, reloaded, _html} = conn |> recycle() |> live(~p"/board/#{board}")
    send(reloaded.pid, {:order_created, association})
    send(reloaded.pid, {:order_created, association})

    assert outgoing_ids(reloaded) == ["outgoing-#{order.id}"]
    assert has_element?(reloaded, "#outgoing-#{order.id} .status", "PENDING")
    reloaded |> element("#outgoing-#{order.id} button", "Deliver") |> render_click()
    send(reloaded.pid, {:order_created, association})

    assert outgoing_ids(reloaded) == ["outgoing-#{order.id}"]
    assert has_element?(reloaded, "#outgoing-#{order.id} .status", "DELIVERED")

    assert has_element?(
             reloaded,
             "#outgoing-#{order.id} .unavailable-action",
             "Already delivered"
           )

    refute has_element?(reloaded, "#outgoing-#{order.id} button")
  end

  test "live insertions and session reloads show the same ten newest unique orders", %{conn: conn} do
    board = board_fixture()
    {_conn, game, player} = join_factory(conn, board)

    orders =
      for _ <- 1..12 do
        order = order_fixture(%{amount: 4, type: "CPU_ORDER"})
        association = player_order_fixture(order, player, "SENDING")
        send(game.pid, {:order_created, association})
        order
      end

    expected = orders |> Enum.reverse() |> Enum.take(10) |> Enum.map(&"outgoing-#{&1.id}")
    assert outgoing_ids(game) == expected
    assert has_element?(game, "[aria-labelledby=outgoing-title] .count-label", "10 orders")
    game |> form("form[phx-submit=create_order]", amount: "600") |> render_submit()
    assert outgoing_ids(game) == expected

    for order <- Enum.take(Enum.reverse(orders), 10) do
      assert has_element?(game, "#outgoing-#{order.id} .status", "PENDING")
    end
  end

  test "outgoing actions explain pending, insufficient-stock, and delivered orders", %{conn: conn} do
    board = board_fixture()
    {_conn, game, player} = join_factory(conn, board)
    ready = order_fixture(%{amount: 4, type: "CPU_ORDER"})
    blocked = order_fixture(%{amount: 1201, type: "CPU_ORDER"})
    delivered = order_fixture(%{amount: 4, type: "CPU_ORDER", state: "DELIVERED"})

    for order <- [ready, blocked, delivered], do: player_order_fixture(order, player, "SENDING")
    assert has_element?(game, "#outgoing-#{ready.id} button[phx-click=deliver_order]", "Deliver")
    assert has_element?(game, "#outgoing-#{blocked.id} button[disabled]", "Not enough stock")

    assert has_element?(
             game,
             "#outgoing-#{delivered.id} .unavailable-action",
             "Already delivered"
           )

    refute has_element?(game, ".unavailable-action", "N/A")

    game |> element("#outgoing-#{ready.id} button", "Deliver") |> render_click()
    assert has_element?(game, "#outgoing-#{ready.id} .status", "DELIVERED")
    assert has_element?(game, "#outgoing-#{ready.id} .unavailable-action", "Already delivered")
    assert has_element?(game, "#outgoing-#{blocked.id} .status", "PENDING")
    assert has_element?(game, "#outgoing-#{blocked.id} button[disabled]", "Not enough stock")
    assert length(outgoing_ids(game)) == 3
  end

  defp outgoing_ids(game) do
    game
    |> render()
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(".outgoing-table tbody tr")
    |> LazyHTML.attribute("id")
  end

  defp join_factory(conn, board) do
    conn = get(conn, ~p"/board/#{board}/player")
    {:ok, selection, _html} = live(conn)

    {:ok, game, _html} =
      selection
      |> element("[phx-value-role=factory]")
      |> render_click()
      |> follow_redirect(conn, ~p"/board/#{board}")

    {conn, game, hd(Boards.get_board!(board.id).players)}
  end
end
