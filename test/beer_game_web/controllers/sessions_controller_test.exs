defmodule BeerGameWeb.SessionsControllerTest do
  use BeerGameWeb.ConnCase

  import BeerGame.SessionFixtures

  @create_attrs %{full: true, name: "some name", session_id: "some session_id"}
  @update_attrs %{full: false, name: "some updated name", session_id: "some updated session_id"}
  @invalid_attrs %{full: nil, name: nil, session_id: nil}

  describe "index" do
    test "lists all sessions", %{conn: conn} do
      conn = get(conn, Routes.sessions_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Sessions"
    end
  end

  describe "new sessions" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.sessions_path(conn, :new))
      assert html_response(conn, 200) =~ "New Sessions"
    end
  end

  describe "create sessions" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.sessions_path(conn, :create), sessions: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.sessions_path(conn, :show, id)

      conn = get(conn, Routes.sessions_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Sessions"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.sessions_path(conn, :create), sessions: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Sessions"
    end
  end

  describe "edit sessions" do
    setup [:create_sessions]

    test "renders form for editing chosen sessions", %{conn: conn, sessions: sessions} do
      conn = get(conn, Routes.sessions_path(conn, :edit, sessions))
      assert html_response(conn, 200) =~ "Edit Sessions"
    end
  end

  describe "update sessions" do
    setup [:create_sessions]

    test "redirects when data is valid", %{conn: conn, sessions: sessions} do
      conn = put(conn, Routes.sessions_path(conn, :update, sessions), sessions: @update_attrs)
      assert redirected_to(conn) == Routes.sessions_path(conn, :show, sessions)

      conn = get(conn, Routes.sessions_path(conn, :show, sessions))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, sessions: sessions} do
      conn = put(conn, Routes.sessions_path(conn, :update, sessions), sessions: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Sessions"
    end
  end

  describe "delete sessions" do
    setup [:create_sessions]

    test "deletes chosen sessions", %{conn: conn, sessions: sessions} do
      conn = delete(conn, Routes.sessions_path(conn, :delete, sessions))
      assert redirected_to(conn) == Routes.sessions_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.sessions_path(conn, :show, sessions))
      end
    end
  end

  defp create_sessions(_) do
    sessions = sessions_fixture()
    %{sessions: sessions}
  end
end
