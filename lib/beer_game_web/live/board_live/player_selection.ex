defmodule BeerGameWeb.BoardLive.PlayerSelection do
  use BeerGameWeb, :live_view

  alias BeerGame.Boards
  alias BeerGame.Orders

  @impl true
  def mount(_params, session, socket) do
    player = Map.get(session, "player")
    board = Map.get(session, "board")

    if player != nil and board != nil do
      IO.puts("User is already in a game")

      {:ok,
       socket
       |> push_redirect(to: Routes.board_show_path(socket, :show, board))}
    else
      socket =
        socket
        |> PhoenixLiveSession.maybe_subscribe(session)
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

  def handle_info({:live_session_updated, session}, socket) do
    {:noreply, put_session_assigns(socket, session)}
  end

  @impl true
  def handle_info({:player_created, player}, socket) do
    IO.puts("Player creted #{player.id}")

    {:noreply,
     update(socket, :available_roles, fn roles ->
       Enum.filter(roles, fn role -> role != player.role end)
     end)}
  end

  @impl true
  def handle_info({:player_deleted, player}, socket) do
    IO.puts("Player deleted #{player.id}")
    {:noreply, update(socket, :available_roles, fn roles -> [player.role | roles] end)}
  end

  @impl true
  def handle_info({:board_updated, board}, socket) do
    {:noreply, update(socket, :board, board)}
  end

  @impl true
  def handle_event("select_role", %{"role" => role}, socket) do
    case Boards.create_player_by_role(role, socket.assigns[:board]) do
      {:ok, player} ->
        board = Boards.get_board!(socket.assigns[:board].id)
        available_roles = resolve_available_roles(board.players)
        if Enum.empty?(available_roles), do: Boards.update_board(board, %{full: true})

        PhoenixLiveSession.put_session(socket, "player", player)
        PhoenixLiveSession.put_session(socket, "board", board)

        Orders.create_cpu_order_data(player)

        {:noreply,
         socket
         |> push_redirect(to: Routes.board_show_path(socket, :show, board))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp put_session_assigns(socket, session) do
    socket
    |> assign(:board, Map.get(session, "board"))
    |> assign(:player, Map.get(session, "player"))
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
