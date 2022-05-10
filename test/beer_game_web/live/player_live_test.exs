defmodule BeerGameWeb.PlayerLiveTest do
  use BeerGameWeb.ConnCase

  import Phoenix.LiveViewTest
  import BeerGame.GameFixtures

  @create_attrs %{backlog: "some backlog", lastOrder: "some lastOrder", name: "some name", role: "some role", stock: "some stock", weeklyOrders: "some weeklyOrders"}
  @update_attrs %{backlog: "some updated backlog", lastOrder: "some updated lastOrder", name: "some updated name", role: "some updated role", stock: "some updated stock", weeklyOrders: "some updated weeklyOrders"}
  @invalid_attrs %{backlog: nil, lastOrder: nil, name: nil, role: nil, stock: nil, weeklyOrders: nil}

  defp create_player(_) do
    player = player_fixture()
    %{player: player}
  end

  describe "Index" do
    setup [:create_player]

    test "lists all player", %{conn: conn, player: player} do
      {:ok, _index_live, html} = live(conn, Routes.player_index_path(conn, :index))

      assert html =~ "Listing Player"
      assert html =~ player.backlog
    end

    test "saves new player", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.player_index_path(conn, :index))

      assert index_live |> element("a", "New Player") |> render_click() =~
               "New Player"

      assert_patch(index_live, Routes.player_index_path(conn, :new))

      assert index_live
             |> form("#player-form", player: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#player-form", player: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.player_index_path(conn, :index))

      assert html =~ "Player created successfully"
      assert html =~ "some backlog"
    end

    test "updates player in listing", %{conn: conn, player: player} do
      {:ok, index_live, _html} = live(conn, Routes.player_index_path(conn, :index))

      assert index_live |> element("#player-#{player.id} a", "Edit") |> render_click() =~
               "Edit Player"

      assert_patch(index_live, Routes.player_index_path(conn, :edit, player))

      assert index_live
             |> form("#player-form", player: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#player-form", player: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.player_index_path(conn, :index))

      assert html =~ "Player updated successfully"
      assert html =~ "some updated backlog"
    end

    test "deletes player in listing", %{conn: conn, player: player} do
      {:ok, index_live, _html} = live(conn, Routes.player_index_path(conn, :index))

      assert index_live |> element("#player-#{player.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#player-#{player.id}")
    end
  end

  describe "Show" do
    setup [:create_player]

    test "displays player", %{conn: conn, player: player} do
      {:ok, _show_live, html} = live(conn, Routes.player_show_path(conn, :show, player))

      assert html =~ "Show Player"
      assert html =~ player.backlog
    end

    test "updates player within modal", %{conn: conn, player: player} do
      {:ok, show_live, _html} = live(conn, Routes.player_show_path(conn, :show, player))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Player"

      assert_patch(show_live, Routes.player_show_path(conn, :edit, player))

      assert show_live
             |> form("#player-form", player: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#player-form", player: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.player_show_path(conn, :show, player))

      assert html =~ "Player updated successfully"
      assert html =~ "some updated backlog"
    end
  end
end
