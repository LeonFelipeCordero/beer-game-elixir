defmodule BeerGameWeb.UIRedesignTest do
  use BeerGameWeb.ConnCase

  import Phoenix.LiveViewTest
  import BeerGame.GameFixtures

  test "setup and board screens share navigation and theme", %{conn: conn} do
    board = board_fixture()

    for path <- [~p"/", ~p"/board/new", ~p"/board", ~p"/board/#{board}/player"] do
      {:ok, view, _html} = live(conn, path)
      assert has_element?(view, ".masthead a[href='/']", "BEER GAME")
      assert has_element?(view, "nav[aria-label='Main navigation'] a[href='/board']", "Boards")
      assert has_element?(view, "#main-content h1")
      assert has_element?(view, ".site-footer", "Systems thinking in practice")
    end
  end

  test "setup exposes the current funnel step", %{conn: conn} do
    {:ok, landing, _} = live(conn, ~p"/")
    assert has_element?(landing, ".setup-steps [aria-current=step]", "Join board")
    {:ok, creation, _} = live(conn, ~p"/board/new")
    assert has_element?(creation, ".setup-steps [aria-current=step]", "Create board")
    {:ok, selection, _} = live(conn, ~p"/board/#{board_fixture()}/player")
    assert has_element?(selection, ".setup-steps [aria-current=step]", "Choose role")
    assert has_element?(selection, "button[aria-label='Play as Retailer']")
  end

  test "empty board index keeps a usable creation action", %{conn: conn} do
    {:ok, view, _} = live(conn, ~p"/board")
    assert has_element?(view, ".empty-state", "No boards yet.")
    assert has_element?(view, ".empty-state a[href='/board/new']", "Create a board")
  end

  test "gameplay highlights only the player's role and explains empty orders", %{conn: conn} do
    board = board_fixture()
    conn = get(conn, ~p"/board/#{board}/player")
    {:ok, selection, _} = live(conn)

    {:ok, game, _} =
      selection
      |> element("[phx-value-role=retailer]")
      |> render_click()
      |> follow_redirect(conn, ~p"/board/#{board}")

    assert has_element?(game, ".chain-stop[aria-current=step]", "Retailer")
    refute has_element?(game, ".chain-stop[aria-current=step]", "Factory")
    assert has_element?(game, ".stock-warning", "Low stock")
    assert has_element?(game, ".waiting-note", "Waiting for the next ordering window.")
    assert has_element?(game, ".order-empty", "Nothing incoming yet.")
    assert has_element?(game, ".order-empty", "No orders to send.")
    assert has_element?(game, "table caption", "Incoming beer orders")
  end

  test "factory exposes an explicit production submission", %{conn: conn} do
    board = board_fixture()
    conn = get(conn, ~p"/board/#{board}/player")
    {:ok, selection, _} = live(conn)

    {:ok, game, _} =
      selection
      |> element("[phx-value-role=factory]")
      |> render_click()
      |> follow_redirect(conn, ~p"/board/#{board}")

    assert has_element?(
             game,
             "form[phx-submit=create_order] button[type=submit]",
             "Save production"
           )

    assert has_element?(game, ".chain-stop[aria-current=step]", "Factory")
    refute has_element?(game, ".waiting-note")
  end
end
