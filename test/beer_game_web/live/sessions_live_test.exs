defmodule BeerGameWeb.SessionsLiveTest do
  use BeerGameWeb.ConnCase

  import Phoenix.LiveViewTest
  import BeerGame.SessionFixtures

  @create_attrs %{full: true, name: "some name", session_id: "some session_id"}
  @update_attrs %{full: false, name: "some updated name", session_id: "some updated session_id"}
  @invalid_attrs %{full: false, name: nil, session_id: nil}

  defp create_sessions(_) do
    sessions = sessions_fixture()
    %{sessions: sessions}
  end

  describe "Index" do
    setup [:create_sessions]

    test "lists all sessions", %{conn: conn, sessions: sessions} do
      {:ok, _index_live, html} = live(conn, Routes.session_index_path(conn, :index))

      assert html =~ "Listing Sessions"
      assert html =~ sessions.name
    end

    test "saves new sessions", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.session_index_path(conn, :index))

      assert index_live |> element("a", "New Sessions") |> render_click() =~
               "New Sessions"

      assert_patch(index_live, Routes.session_new_path(conn, :new))

      assert index_live
             |> form("#sessions-form", sessions: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#sessions-form", sessions: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.session_index_path(conn, :index))

      assert html =~ "Sessions created successfully"
      assert html =~ "some name"
    end

    test "updates sessions in listing", %{conn: conn, sessions: sessions} do
      {:ok, index_live, _html} = live(conn, Routes.session_index_path(conn, :index))

      assert index_live |> element("#sessions-#{sessions.id} a", "Edit") |> render_click() =~
               "Edit Sessions"

      assert_patch(index_live, Routes.session_index_path(conn, :edit, sessions))

      assert index_live
             |> form("#sessions-form", sessions: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#sessions-form", sessions: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.session_index_path(conn, :index))

      assert html =~ "Sessions updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes sessions in listing", %{conn: conn, sessions: sessions} do
      {:ok, index_live, _html} = live(conn, Routes.session_index_path(conn, :index))

      assert index_live |> element("#sessions-#{sessions.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#sessions-#{sessions.id}")
    end
  end

  describe "Show" do
    setup [:create_sessions]

    test "displays sessions", %{conn: conn, sessions: sessions} do
      {:ok, _show_live, html} = live(conn, Routes.session_show_path(conn, :show, sessions))

      assert html =~ "Show Sessions"
      assert html =~ sessions.name
    end

    test "updates sessions within modal", %{conn: conn, sessions: sessions} do
      {:ok, show_live, _html} = live(conn, Routes.session_show_path(conn, :show, sessions))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Sessions"

      assert_patch(show_live, Routes.session_show_path(conn, :edit, sessions))

      assert show_live
             |> form("#sessions-form", sessions: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#sessions-form", sessions: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.session_show_path(conn, :show, sessions))

      assert html =~ "Sessions updated successfully"
      assert html =~ "some updated name"
    end
  end
end
