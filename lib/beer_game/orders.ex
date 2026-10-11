defmodule BeerGame.Orders do
  import Ecto.Query, warn: false
  alias BeerGame.Repo

  alias BeerGame.Game.Order
  alias BeerGame.Game.Player
  alias BeerGame.Game.PlayerOrders
  alias BeerGame.Game.CpuOrderData

  def list_orders do
    Repo.all(Order)
  end

  def get_order!(id), do: Repo.get!(Order, id)

  def create_order(attrs \\ %{}) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  def create_player_order(order, player), do: create_player_order(%{}, order, player)

  def create_player_order(attrs, order, player) do
    insert_player_order(attrs, order, player)
    |> broadcast_player_order(:order_created)
  end

  def update_order(%Order{} = order, attrs) do
    order
    |> Order.changeset(attrs)
    |> Repo.update()
    |> broadcast_order(:order_updated)
  end

  def delete_order(%Order{} = order) do
    Repo.delete(order)
  end

  def change_order(%Order{} = order, attrs \\ %{}) do
    Order.changeset(order, attrs)
  end

  def get_by_player(player_id) do
    Order
    |> where(player_id: ^player_id)
    |> Repo.one()
  end

  def get_by_contrapart(contrapart) do
    Order
    |> where(contrapart: ^contrapart)
    |> Repo.one()
  end

  def create_orders(socket, amount) do
    result =
      Repo.transact(fn ->
        players =
          Repo.all(
            from p in Player,
              where: p.board_id == ^socket.assigns.board.id,
              order_by: p.id,
              lock: "FOR UPDATE"
          )

        with %Player{} = player <- Enum.find(players, &(&1.id == socket.assigns.player.id)),
             %Player{} = supplier <- find_supplier(players, player.role),
             {:ok, order} <- create_order(%{amount: amount, type: "PLAYER_ORDER"}),
             {:ok, receiving} <- insert_player_order(%{type: "RECEIVING"}, order, player),
             {:ok, sending} <- insert_player_order(%{type: "SENDING"}, order, supplier) do
          {:ok, {order, [receiving, sending]}}
        else
          nil -> {:error, :supplier_unavailable}
          {:error, _reason} = error -> error
        end
      end)

    case result do
      {:ok, {order, associations}} ->
        Enum.each(associations, &broadcast_player_order({:ok, &1}, :order_created))
        order

      {:error, _reason} = error ->
        error
    end
  end

  def deliver_order(order_id, player_id), do: BeerGame.OrderDelivery.deliver(order_id, player_id)

  def create_cpu_orders(player) do
    result =
      Repo.transact(fn ->
        with %Player{} = player <-
               Repo.one(from p in Player, where: p.id == ^player.id, lock: "FOR UPDATE"),
             %CpuOrderData{} = data <- get_cpu_order_data_by_player(player.id),
             {:ok, order} <- create_order(%{amount: data.amount, type: "CPU_ORDER"}),
             {:ok, association} <- insert_player_order(%{type: "SENDING"}, order, player),
             {:ok, data} <- update_cpu_order_data(data) do
          {:ok, {association, data}}
        else
          nil -> {:error, :player_not_found}
          {:error, _reason} = error -> error
        end
      end)

    case result do
      {:ok, {association, data}} ->
        broadcast_player_order({:ok, association}, :order_created)
        {:ok, data}

      {:error, _reason} = error ->
        error
    end
  end

  def get_player_orders(order_id) do
    PlayerOrders
    |> where(order_id: ^order_id)
    |> Repo.all()
    |> Repo.preload([:player, :order])
  end

  def create_cpu_order_data(player) do
    %CpuOrderData{}
    |> CpuOrderData.changeset(%{amount: player.weekly_orders})
    |> Ecto.Changeset.put_assoc(:player, player)
    |> Repo.insert()
  end

  def subscribe(topic) do
    Phoenix.PubSub.subscribe(BeerGame.PubSub, topic)
  end

  defp find_supplier(players, role) do
    supplier_role = %{"retailer" => "wholesaler", "wholesaler" => "factory"}[role]
    Enum.find(players, &(&1.role == supplier_role))
  end

  defp insert_player_order(attrs, order, player) do
    %PlayerOrders{}
    |> PlayerOrders.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:order, order)
    |> Ecto.Changeset.put_assoc(:player, player)
    |> Repo.insert()
  end

  defp broadcast_player_order({:error, _} = error, _event), do: error

  defp broadcast_player_order({:ok, player_order}, event) do
    Phoenix.PubSub.broadcast!(BeerGame.PubSub, "player_orders", {event, player_order})
    {:ok, player_order}
  end

  defp broadcast_order({:error, _} = error, _event), do: error

  defp broadcast_order({:ok, order}, event) do
    Phoenix.PubSub.broadcast!(BeerGame.PubSub, "orders", {event, order})
    {:ok, order}
  end

  defp get_cpu_order_data_by_player(player_id) do
    CpuOrderData
    |> where(player_id: ^player_id)
    |> Repo.one()
  end

  defp update_cpu_order_data(cpu_order_data) do
    new_amount =
      if cpu_order_data.amount < 10 do
        cpu_order_data.amount + 2
      else
        Integer.floor_div(cpu_order_data.amount, 5)
      end

    cpu_order_data
    |> CpuOrderData.changeset(%{amount: new_amount + cpu_order_data.amount})
    |> Repo.update()
  end
end
