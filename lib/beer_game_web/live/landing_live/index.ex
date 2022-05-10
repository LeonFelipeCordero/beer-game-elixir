defmodule BeerGameWeb.LandingLive.Index do
  use BeerGameWeb, :live_view

  alias BeerGame.Boards

  @impl true
  def mount(_params, _landing, socket) do
    socket =
      socket
      |> assign(:name, "")

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "join_board",
        %{"name" => name},
        socket
      ) do
    board = Boards.get_by_name(name)

    {:noreply,
     push_redirect(socket,
       to: Routes.board_player_selection_path(socket, :player_selection, board)
     )}
  end
end
