defmodule BeerGameWeb.BoardLive.New do
  use BeerGameWeb, :live_view

  alias BeerGame.Boards

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:name, "")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Board")
    |> assign(:name, "")
  end

  @impl true
  def handle_event("create_board", %{"name" => name}, socket) do
    case Boards.create_board(%{name: name}) do
      {:ok, board} ->
        {:noreply,
         socket
         |> put_flash(:info, "Board created successfully")
         |> push_redirect(
           to: Routes.board_player_selection_path(socket, :player_selection, board)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
