defmodule BeerGameWeb.BoardLive.Show do
  use BeerGameWeb, :live_view

  alias BeerGame.{Boards, Orders, Repo}
  alias BeerGame.Game.{Board, Player}
  alias BeerGameWeb.LiveSession

  @impl true
  def mount(_params, session, socket) do
    session = LiveSession.get_session(session)

    if connected?(socket) do
      Enum.each(
        ~w(player_orders orders players order_time cpu_orders factory),
        &Orders.subscribe/1
      )
    end

    {:ok, socket |> LiveSession.maybe_subscribe(session) |> put_session_assigns(session)}
  end

  @impl true
  def handle_info({:live_session_updated, _session}, socket) do
    session = LiveSession.get_session(%{"live_session_id" => socket.private.live_session_id})
    {:noreply, put_session_assigns(socket, session)}
  end

  def handle_info({:order_created, player_order}, socket) do
    if player_order.type == "SENDING" and player_order.player_id == socket.assigns.player.id do
      order = Orders.get_order!(player_order.order_id)
      {:noreply, update(socket, :sending_orders, &[order | &1])}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:order_updated, order}, socket) do
    {:noreply,
     socket
     |> update(:sending_orders, &replace_order(&1, order))
     |> update(:receiving_orders, &replace_order(&1, order))}
  end

  def handle_info({event, player}, socket) when event in [:player_created, :player_deleted] do
    cond do
      event == :player_deleted and player.id == socket.assigns.player.id ->
        {:noreply, push_navigate(socket, to: ~p"/")}

      player.board_id == socket.assigns.board.id ->
        {:noreply, assign(socket, :board, Boards.get_board!(player.board_id))}

      true ->
        {:noreply, socket}
    end
  end

  def handle_info({:player_updated, player}, socket) do
    socket =
      if player.id == socket.assigns.player.id, do: assign(socket, :player, player), else: socket

    {:noreply, socket}
  end

  def handle_info({:order_time_command, _value}, socket) do
    with_player(socket, fn socket ->
      LiveSession.put_session(socket, "order_time", true)
      assign(socket, :order_time, true)
    end)
  end

  def handle_info({:cpu_order_command}, socket) do
    with_player(socket, fn socket ->
      Orders.create_cpu_orders(socket.assigns.player)
      socket
    end)
  end

  def handle_info({:factory_deliver}, socket) do
    with_player(socket, fn socket ->
      player = socket.assigns.player

      if player.role == "factory", do: Boards.produce_stock(player.id)

      socket
    end)
  end

  @impl true
  def handle_event("abandon_game", _params, socket) do
    Boards.delete_player_by_role(socket.assigns.player)
    LiveSession.put_session(socket, "board", nil)
    LiveSession.put_session(socket, "player", nil)
    LiveSession.put_session(socket, "order_time", false)
    {:noreply, push_navigate(socket, to: ~p"/")}
  end

  def handle_event("create_order", %{"amount" => amount}, socket) do
    with_player(socket, fn socket ->
      changeset = Player.changeset(socket.assigns.player, %{weekly_orders: amount})
      submit_order(socket, changeset)
    end)
  end

  def handle_event("deliver_order", %{"order_id" => order_id}, socket) do
    case Orders.deliver_order(order_id, socket.assigns.player.id) do
      {:ok, _order} -> {:noreply, socket}
      {:error, _reason} -> {:noreply, put_flash(socket, :error, "Order cannot be delivered")}
    end
  end

  defp submit_order(socket, %{valid?: false}),
    do: put_flash(socket, :error, "Invalid order amount")

  defp submit_order(socket, changeset) do
    amount = Ecto.Changeset.get_field(changeset, :weekly_orders)

    result =
      if socket.assigns.player.role == "factory",
        do: :ok,
        else: Orders.create_orders(socket, amount)

    case result do
      {:error, _reason} ->
        put_flash(socket, :error, "Supplier is unavailable")

      _ ->
        player = Boards.update_weekly_order(socket.assigns.player, amount, socket)
        LiveSession.put_session(socket, "order_time", false)
        assign(socket, player: player, order_time: false)
    end
  end

  defp with_player(socket, callback) do
    case Repo.get(Player, socket.assigns.player.id) do
      nil -> {:noreply, push_navigate(socket, to: ~p"/")}
      player -> {:noreply, callback.(assign(socket, :player, player))}
    end
  end

  defp put_session_assigns(socket, session) do
    with %{id: board_id} <- Map.get(session, "board"),
         %{id: player_id} <- Map.get(session, "player"),
         %Board{} = board <- Repo.get(Board, board_id),
         %Player{board_id: ^board_id} = player <- Repo.get(Player, player_id) do
      player = Repo.preload(player, player_orders: :order)

      socket
      |> assign(:page_title, "Board #{board.name}")
      |> assign(:board, Repo.preload(board, :players))
      |> assign(:player, player)
      |> assign(:sending_orders, recent_orders(player.player_orders, "SENDING"))
      |> assign(:receiving_orders, recent_orders(player.player_orders, "RECEIVING"))
      |> assign(:order_time, Map.get(session, "order_time", false))
    else
      _ -> push_navigate(socket, to: ~p"/")
    end
  end

  defp recent_orders(player_orders, type) do
    player_orders
    |> Enum.reverse()
    |> Enum.filter(&(&1.type == type))
    |> Enum.take(10)
    |> Enum.map(& &1.order)
  end

  defp replace_order(orders, order) do
    if Enum.any?(orders, &(&1.id == order.id)) do
      [order | Enum.reject(orders, &(&1.id == order.id))] |> Enum.sort_by(& &1.id, :desc)
    else
      orders
    end
  end
end
