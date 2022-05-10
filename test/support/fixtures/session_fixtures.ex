defmodule BeerGame.SessionFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BeerGame.Session` context.
  """

  @doc """
  Generate a sessions.
  """
  def sessions_fixture(attrs \\ %{}) do
    {:ok, sessions} =
      attrs
      |> Enum.into(%{
        full: true,
        name: "some name",
        session_id: "some session_id"
      })
      |> BeerGame.Session.create_sessions()

    sessions
  end
end
