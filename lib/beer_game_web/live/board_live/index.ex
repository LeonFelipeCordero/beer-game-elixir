defmodule BeerGameWeb.BoardLive.Index do
  use BeerGameWeb, :live_view

  alias BeerGame.Boards
  alias BeerGame.Game.Board
  alias BeerGame.Repo

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Boards", board_collection: Repo.all(Board))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    {:ok, _board} = id |> Boards.get_board!() |> Boards.delete_board()
    {:noreply, assign(socket, :board_collection, Repo.all(Board))}
  end
end
