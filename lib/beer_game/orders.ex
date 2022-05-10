defmodule BeerGame.Orders do
  import Ecto.Query, warn: false
  alias BeerGame.Repo

  alias BeerGame.Game.Order
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

  def create_player_order(attrs \\ %{}, order, player) do
    %PlayerOrders{}
    |> PlayerOrders.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:order, order)
    |> Ecto.Changeset.put_assoc(:player, player)
    |> Repo.insert()
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
    player = socket.assigns[:player]
    board = socket.assigns[:board]

    contra_part =
      case player.role do
        "retailer" -> Enum.filter(board.players, fn p -> p.role == "wholesaler" end)
        "wholesaler" -> Enum.filter(board.players, fn p -> p.role == "factory" end)
      end
      |> Enum.at(0)

    case create_order(%{amount: amount, type: "PLAYER_ORDER"}) do
      {:ok, order} ->
        create_player_order(%{type: "RECEIVING"}, order, player)
        create_player_order(%{type: "SENDING"}, order, contra_part)
        order

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.puts("something went wrong...")
        IO.inspect(changeset)
    end
  end

  def create_cpu_orders(player) do
    cpu_order_data = get_cpu_order_data_by_player(player.id)

    case create_order(%{amount: cpu_order_data.amount, type: "CPU_ORDER"}) do
      {:ok, order} ->
        create_player_order(%{type: "SENDING"}, order, player)
        update_cpu_order_data(cpu_order_data)

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.puts("something went wrong...")
        IO.inspect(changeset)
    end
  end

  def get_player_orders(order_id) do
    PlayerOrders
    |> where(order_id: ^order_id)
    |> Repo.all()
    |> Repo.preload(:player)
    |> Repo.preload(:order)
  end

  def create_cpu_order_data(player) do
    IO.inspect(player)

    %CpuOrderData{}
    |> CpuOrderData.changeset(%{amount: player.weeklyOrders})
    |> Ecto.Changeset.put_assoc(:player, player)
    |> Repo.insert()
  end

  def subscribe(topic) do
    Phoenix.PubSub.subscribe(BeerGame.PubSub, topic)
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
      cond do
        cpu_order_data.amount < 10 -> cpu_order_data.amount + 2
        true -> Integer.floor_div(cpu_order_data.amount, 5)
      end

    cpu_order_data
    |> CpuOrderData.changeset(%{amount: new_amount + cpu_order_data.amount})
    |> Repo.update()
  end
end
