defmodule BeerGameWeb.BoardLive.PlayerSelection do
  use BeerGameWeb, :live_view

  alias BeerGame.Boards
  alias BeerGame.Orders
  alias BeerGameWeb.LiveSession

  @impl true
  def mount(_params, session, socket) do
    session = LiveSession.get_session(session)
    player = Map.get(session, "player")
    board = Map.get(session, "board")

    if player != nil and board != nil do
      {:ok, push_navigate(socket, to: ~p"/board/#{board}")}
    else
      socket =
        socket
        |> LiveSession.maybe_subscribe(session)
        |> put_session_assigns(session)

      if connected?(socket) do
        Boards.subscribe("players")
        Boards.subscribe("board")
      end

      {:ok, socket}
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    board = Boards.get_board!(id)
    available_roles = resolve_available_roles(board.players)

    {:noreply,
     socket
     |> assign(:page_title, "Player Selection")
     |> assign(:board, board)
     |> assign(:available_roles, available_roles)}
  end

  @impl true
  def handle_info({:live_session_updated, _session}, socket) do
    session = LiveSession.get_session(%{"live_session_id" => socket.private.live_session_id})
    {:noreply, assign(socket, :player, Map.get(session, "player"))}
  end

  def handle_info({event, player}, socket)
      when event in [:player_created, :player_deleted, :player_updated] do
    {:noreply, refresh_board(socket, player.board_id)}
  end

  def handle_info({:board_updated, board}, socket) do
    {:noreply, refresh_board(socket, board.id)}
  end

  @impl true
  def handle_event("select_role", %{"role" => role}, socket) do
    case Boards.create_player_by_role(role, socket.assigns[:board]) do
      {:ok, player} ->
        board = Boards.get_board!(socket.assigns[:board].id)
        available_roles = resolve_available_roles(board.players)
        if Enum.empty?(available_roles), do: Boards.update_board(board, %{full: true})

        LiveSession.put_session(socket, "player", player)
        LiveSession.put_session(socket, "board", board)

        Orders.create_cpu_order_data(player)

        {:noreply,
         socket
         |> push_navigate(to: ~p"/board/#{board}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp put_session_assigns(socket, session) do
    socket
    |> assign(:board, Map.get(session, "board"))
    |> assign(:player, Map.get(session, "player"))
  end

  defp refresh_board(socket, board_id) do
    if board_id == socket.assigns.board.id do
      board = Boards.get_board!(board_id)
      assign(socket, board: board, available_roles: resolve_available_roles(board.players))
    else
      socket
    end
  end

  defp resolve_available_roles(players) do
    roles = ["retailer", "wholesaler", "factory"]

    selected_roles =
      players
      |> Enum.map(fn player -> player.role end)
      |> Enum.uniq()

    Enum.filter(roles, fn role -> role not in selected_roles end)
  end
end
