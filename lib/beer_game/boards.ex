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
    |> broadcast_session(:board_updated)
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
    |> Repo.preload([:player_orders, :orders])
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
    result =
      Repo.transact(fn ->
        with {:ok, deleted} <- Repo.delete(Player.changeset(player, %{})),
             {:ok, board} <- clear_full_board(player.board_id) do
          {:ok, {deleted, board}}
        end
      end)

    case result do
      {:ok, {deleted, board}} ->
        if board, do: broadcast_session({:ok, board}, :board_updated)
        broadcast_player({:ok, deleted}, :player_deleted)

      {:error, _reason} = error ->
        error
    end
  end

  def update_weekly_order(player, amount, socket) do
    case update_player(player, %{weekly_orders: amount}) do
      {:ok, updated_player} ->
        BeerGameWeb.LiveSession.put_session(socket, "player", updated_player)
        updated_player

      {:error, _changeset} ->
        player
    end
  end

  def produce_stock(player_id) do
    Repo.transact(fn ->
      case Repo.one(
             from p in Player,
               where: p.id == ^player_id and p.role == "factory",
               lock: "FOR UPDATE"
           ) do
        nil ->
          {:error, :player_not_found}

        player ->
          Repo.update(Player.changeset(player, %{stock: player.stock + player.weekly_orders}))
      end
    end)
    |> broadcast_player(:player_updated)
  end

  def deliver_order(player_orders, order) do
    Enum.each(player_orders, fn po ->
      if po.type == "SENDING" do
        update_player(po.player, %{
          stock: po.player.stock - order.amount
        })
      else
        update_player(po.player, %{
          stock: po.player.stock + order.amount,
          last_order: order.amount
        })
      end
    end)
  end

  def subscribe(topic) do
    Phoenix.PubSub.subscribe(BeerGame.PubSub, topic)
  end

  defp clear_full_board(board_id) do
    case Repo.one(from b in Board, where: b.id == ^board_id and b.full, lock: "FOR UPDATE") do
      nil -> {:ok, nil}
      board -> Repo.update(Board.changeset(board, %{full: false}))
    end
  end

  defp broadcast_player({:error, _reason} = error, _event), do: error

  defp broadcast_player({:ok, player}, event) do
    Phoenix.PubSub.broadcast(BeerGame.PubSub, "players", {event, player})
    {:ok, player}
  end

  defp broadcast_session({:error, _reason} = error, _event), do: error

  defp broadcast_session({:ok, board}, event) do
    Phoenix.PubSub.broadcast(BeerGame.PubSub, "board", {event, board})
    {:ok, board}
  end

  defp create_retailer(cpu) do
    %Player{
      name: "Retailer",
      role: "retailer",
      backlog: 8,
      last_order: 4,
      weekly_orders: 4,
      stock: 8,
      cpu: cpu
    }
  end

  defp create_wholesaler(cpu) do
    %Player{
      name: "Wholesaler",
      role: "wholesaler",
      backlog: 120,
      last_order: 60,
      weekly_orders: 60,
      stock: 120,
      cpu: cpu
    }
  end

  defp create_factory() do
    %Player{
      name: "Factory",
      role: "factory",
      backlog: 1200,
      last_order: 600,
      weekly_orders: 600,
      stock: 1200,
      cpu: false
    }
  end
end
