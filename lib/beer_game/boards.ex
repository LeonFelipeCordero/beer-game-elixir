defmodule BeerGame.Boards do
  import Ecto.Query, warn: false
  alias BeerGame.Repo

  alias BeerGame.Game.Board
  alias BeerGame.Game.Player

  def get_board!(id) do
    Board
    |> Repo.get!(id)
    |> Repo.preload(:players)
  end

  def create_board(attrs \\ %{}) do
    %Board{}
    |> Board.changeset(attrs)
    |> Repo.insert()
  end

  def update_board(%Board{} = board, attrs) do
    board
    |> Board.changeset(attrs)
    |> Repo.update()
    |> broadcast_session(:session_updated)
  end

  def delete_board(%Board{} = board) do
    Repo.delete(board)
  end

  def change_board(%Board{} = board, attrs \\ %{}) do
    Board.changeset(board, attrs)
  end

  def get_by_name(name) do
    Board
    |> where(name: ^name)
    |> Repo.one()
  end

  def get_player(id) do
    Player
    |> Repo.get!(id)
    |> Repo.preload(:player_orders)
    |> Repo.preload(:orders)
  end

  def list_players do
    Repo.all(Player)
  end

  def update_player(%Player{} = player, attrs) do
    player
    |> Player.changeset(attrs)
    |> Repo.update()
    |> broadcast_player(:player_updated)
  end

  def create_player_by_role(role, board) do
    player =
      case role do
        "retailer" -> create_retailer(false)
        "wholesaler" -> create_wholesaler(false)
        "factory" -> create_factory()
      end

    player
    |> Player.changeset(%{})
    |> Ecto.Changeset.put_assoc(:board, board)
    |> Repo.insert()
    |> broadcast_player(:player_created)
  end

  def delete_player_by_role(player) do
    player
    |> Player.changeset(%{})
    |> Repo.delete()
    |> broadcast_player(:player_deleted)
  end

  def update_weekly_order(player, amount, socket) do
    attrs = %{weeklyOrders: amount}
    update_player(player, attrs)
    new_player = Map.put(player, :weeklyOrders, amount)

    PhoenixLiveSession.put_session(socket, "player", new_player)

    new_player
  end

  def deliver_order(player_orders, order) do
    player_orders
    |> Enum.each(fn po ->
      if po.type == "SENDING" do
        update_player(po.player, %{
          :stock => po.player.stock - order.amount
        })
      else
        update_player(po.player, %{
          :stock => po.player.stock + order.amount,
          :lastOrder => order.amount
        })
      end
    end)
  end

  def subscribe(topic) do
    Phoenix.PubSub.subscribe(BeerGame.PubSub, topic)
  end

  defp broadcast_player({:error, _reason} = error, _event), do: error

  defp broadcast_player({:ok, player}, event) do
    IO.inspect(event)
    Phoenix.PubSub.broadcast(BeerGame.PubSub, "players", {event, player})
    {:ok, player}
  end

  defp broadcast_session({:error, _reason} = error, _event), do: error

  defp broadcast_session({:ok, board}, event) do
    Phoenix.PubSub.broadcast(BeerGame.PubSub, "board", {event, board})
    {:ok, board}
  end

  defp create_retailer(cpu \\ true) do
    %Player{
      name: "Retailer",
      role: "retailer",
      backlog: 8,
      lastOrder: 4,
      weeklyOrders: 4,
      stock: 8,
      cpu: cpu
    }
  end

  defp create_wholesaler(cpu \\ true) do
    %Player{
      name: "Wholesaler",
      role: "wholesaler",
      backlog: 120,
      lastOrder: 60,
      weeklyOrders: 60,
      stock: 120,
      cpu: cpu
    }
  end

  defp create_factory() do
    %Player{
      name: "Factory",
      role: "factory",
      backlog: 1200,
      lastOrder: 600,
      weeklyOrders: 600,
      stock: 1200,
      cpu: false
    }
  end
end
