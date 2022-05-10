defmodule BeerGame.SessionTest do
  use BeerGame.DataCase

  alias BeerGame.Session

  describe "sessions" do
    alias BeerGame.Session.Sessions

    import BeerGame.SessionFixtures

    @invalid_attrs %{full: nil, name: nil, session_id: nil}

    test "list_sessions/0 returns all sessions" do
      sessions = sessions_fixture()
      assert Session.list_sessions() == [sessions]
    end

    test "get_sessions!/1 returns the sessions with given id" do
      sessions = sessions_fixture()
      assert Session.get_sessions!(sessions.id) == sessions
    end

    test "create_sessions/1 with valid data creates a sessions" do
      valid_attrs = %{full: true, name: "some name", session_id: "some session_id"}

      assert {:ok, %Sessions{} = sessions} = Session.create_sessions(valid_attrs)
      assert sessions.full == true
      assert sessions.name == "some name"
      assert sessions.session_id == "some session_id"
    end

    test "create_sessions/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Session.create_sessions(@invalid_attrs)
    end

    test "update_sessions/2 with valid data updates the sessions" do
      sessions = sessions_fixture()

      update_attrs = %{
        full: false,
        name: "some updated name",
        session_id: "some updated session_id"
      }

      assert {:ok, %Sessions{} = sessions} = Session.update_sessions(sessions, update_attrs)
      assert sessions.full == false
      assert sessions.name == "some updated name"
      assert sessions.session_id == "some updated session_id"
    end

    test "update_sessions/2 with invalid data returns error changeset" do
      sessions = sessions_fixture()
      assert {:error, %Ecto.Changeset{}} = Session.update_sessions(sessions, @invalid_attrs)
      assert sessions == Session.get_sessions!(sessions.id)
    end

    test "delete_sessions/1 deletes the sessions" do
      sessions = sessions_fixture()
      assert {:ok, %Sessions{}} = Session.delete_sessions(sessions)
      assert_raise Ecto.NoResultsError, fn -> Session.get_sessions!(sessions.id) end
    end

    test "change_sessions/1 returns a sessions changeset" do
      sessions = sessions_fixture()
      assert %Ecto.Changeset{} = Session.change_sessions(sessions)
    end
  end

  describe "sessions" do
    alias BeerGame.Session.Sessions

    import BeerGame.SessionFixtures

    @invalid_attrs %{full: nil, name: nil, session_id: nil}

    test "list_sessions/0 returns all sessions" do
      sessions = sessions_fixture()
      assert Session.list_sessions() == [sessions]
    end

    test "get_sessions!/1 returns the sessions with given id" do
      sessions = sessions_fixture()
      assert Session.get_sessions!(sessions.id) == sessions
    end

    test "create_sessions/1 with valid data creates a sessions" do
      valid_attrs = %{full: true, name: "some name", session_id: "some session_id"}

      assert {:ok, %Sessions{} = sessions} = Session.create_sessions(valid_attrs)
      assert sessions.full == true
      assert sessions.name == "some name"
      assert sessions.session_id == "some session_id"
    end

    test "create_sessions/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Session.create_sessions(@invalid_attrs)
    end

    test "update_sessions/2 with valid data updates the sessions" do
      sessions = sessions_fixture()
      update_attrs = %{full: false, name: "some updated name", session_id: "some updated session_id"}

      assert {:ok, %Sessions{} = sessions} = Session.update_sessions(sessions, update_attrs)
      assert sessions.full == false
      assert sessions.name == "some updated name"
      assert sessions.session_id == "some updated session_id"
    end

    test "update_sessions/2 with invalid data returns error changeset" do
      sessions = sessions_fixture()
      assert {:error, %Ecto.Changeset{}} = Session.update_sessions(sessions, @invalid_attrs)
      assert sessions == Session.get_sessions!(sessions.id)
    end

    test "delete_sessions/1 deletes the sessions" do
      sessions = sessions_fixture()
      assert {:ok, %Sessions{}} = Session.delete_sessions(sessions)
      assert_raise Ecto.NoResultsError, fn -> Session.get_sessions!(sessions.id) end
    end

    test "change_sessions/1 returns a sessions changeset" do
      sessions = sessions_fixture()
      assert %Ecto.Changeset{} = Session.change_sessions(sessions)
    end
  end
end
