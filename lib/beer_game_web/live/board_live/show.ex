defmodule BeerGameWeb.BoardLive.Show do
  use BeerGameWeb, :live_view

  alias BeerGame.Boards
  alias BeerGame.Orders

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      Orders.subscribe("player_orders")
      Orders.subscribe("orders")
      Orders.subscribe("players")
      Orders.subscribe("order_time")
      Orders.subscribe("cpu_orders")
      Orders.subscribe("factory")
    end

    {:ok,
     socket
     |> PhoenixLiveSession.maybe_subscribe(session)
     |> put_session_assigns(session)}
  end

  @impl true
  def handle_info({:live_session_updated, session}, socket) do
    {:noreply, put_session_assigns(socket, session)}
  end

  @impl true
  def handle_info({:order_created, player_order}, socket) do
    player_id = player_order.player.id
    order = Orders.get_order!(player_order.order.id)

    IO.puts("""
      Receivev order created, order => #{order.id}, player => #{player_id}
    """)

    cond do
      player_order.type == "RECEIVING" -> {:noreply, socket}
      player_id != socket.assigns[:player].id -> {:noreply, socket}
      true -> {:noreply, update(socket, :sending_orders, fn orders -> [order | orders] end)}
    end
  end

  @impl true
  def handle_info({:order_updated, order}, socket) do
    IO.puts("""
      Receivev order updated, order => #{order.id}
    """)

    sending_order =
      Enum.find(socket.assigns[:sending_orders], fn sending_order ->
        order.id == sending_order.id
      end)

    receiving_order =
      Enum.find(socket.assigns[:receiving_orders], fn receiving_order ->
        order.id == receiving_order.id
      end)

    cond do
      receiving_order != nil ->
        {:noreply,
         update(socket, :receiving_orders, fn orders ->
           rejected = Enum.reject(orders, fn o -> o.id == order.id end)

           [order | rejected]
           |> Enum.sort_by(& &1.id, :desc)
         end)}

      sending_order != nil ->
        {:noreply,
         update(socket, :sending_orders, fn orders ->
           rejected = Enum.reject(orders, fn o -> o.id == order.id end)

           [order | rejected]
           |> Enum.sort_by(& &1.id, :desc)
         end)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:player_updated, player}, socket) do
    IO.puts("""
      Receivev player updated, player => #{player.id}
    """)

    if player.id == socket.assigns[:player].id do
      {:noreply, update(socket, :player, fn _ -> player end)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:order_time_command, _value}, socket) do
    IO.puts("Receivev order time action")
    PhoenixLiveSession.put_session(socket, "order_time", true)
    {:noreply, update(socket, :order_time, fn _ -> true end)}
  end

  @impl true
  def handle_info({:cpu_order_command}, socket) do
    IO.puts("Receivev cpu order command")

    socket.assigns[:player]
    |> Orders.create_cpu_orders()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:factory_deliver}, socket) do
    player = socket.assigns[:player]

    if player.role == "factory" do
      IO.puts("Receivev factory delivery command")

      Boards.update_player(player, %{stock: player.stock + player.weeklyOrders})
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("abandon_game", _, socket) do
    player = socket.assigns[:player]

    Boards.delete_player_by_role(player)

    PhoenixLiveSession.put_session(socket, "board", nil)
    PhoenixLiveSession.put_session(socket, "player", nil)

    {:noreply,
     socket
     |> push_redirect(to: Routes.landing_index_path(socket, :index))}
  end

  def handle_event("create_order", %{"amount" => amount}, socket) do
    PhoenixLiveSession.put_session(socket, "order_time", false)
    player = socket.assigns[:player]

    new_player = Boards.update_weekly_order(player, amount, socket)
    Orders.create_orders(socket, amount)

    {:noreply,
     socket
     |> assign(:player, new_player)
     |> assign(:order_time, false)}
  end

  def handle_event("deliver_order", %{"order_id" => order_id}, socket) do
    player_orders = Orders.get_player_orders(order_id)

    order = Enum.at(player_orders, 0).order
    Orders.update_order(order, %{:state => "DELIVERED"})
    Boards.deliver_order(player_orders, order)

    {:noreply, socket}
  end

  defp put_session_assigns(socket, session) do
    session_board = Map.get(session, "board")
    session_player = Map.get(session, "player")
    order_time = Map.get(session, "order_time", false)

    if session_board != nil and session_player != nil do
      board = Boards.get_board!(session_board.id)
      player = Boards.get_player(session_player.id)

      sending_orders =
        Enum.reverse(player.player_orders)
        |> Enum.filter(fn po -> po.type == "SENDING" end)
        |> Enum.take(10)
        |> Enum.map(fn po -> po.order end)

      receiving_orders =
        Enum.reverse(player.player_orders)
        |> Enum.filter(fn po -> po.type == "RECEIVING" end)
        |> Enum.take(10)
        |> Enum.map(fn po -> po.order end)

      socket
      |> assign(:board, board)
      |> assign(:player, player)
      |> assign(:sending_orders, sending_orders)
      |> assign(:receiving_orders, receiving_orders)
      |> assign(:order_time, order_time)
    else
      socket
    end
  end
end
