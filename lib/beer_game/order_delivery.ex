defmodule BeerGame.OrderDelivery do
  import Ecto.Query

  alias BeerGame.Repo
  alias BeerGame.Game.{Order, Player, PlayerOrders}

  def deliver(order_id, player_id) do
    result =
      Repo.transact(fn ->
        with {:ok, order} <- lock_order(order_id),
             associations <- Repo.all(from po in PlayerOrders, where: po.order_id == ^order.id),
             :ok <- authorize_sender(associations, player_id),
             :ok <- pending(order),
             {:ok, sender, receiver} <- lock_participants(associations, order.type),
             :ok <- sufficient_stock(sender, order),
             {:ok, sender} <- update_player(sender, %{stock: sender.stock - order.amount}),
             {:ok, receiver} <- receive_order(receiver, order),
             {:ok, order} <- Repo.update(Order.changeset(order, %{state: "DELIVERED"})) do
          {:ok, {order, Enum.reject([sender, receiver], &is_nil/1)}}
        end
      end)

    case result do
      {:ok, {order, players}} ->
        Enum.each(players, fn player ->
          Phoenix.PubSub.broadcast(BeerGame.PubSub, "players", {:player_updated, player})
        end)

        Phoenix.PubSub.broadcast(BeerGame.PubSub, "orders", {:order_updated, order})
        {:ok, order}

      {:error, _reason} = error ->
        error
    end
  end

  defp lock_order(id) do
    with {:ok, id} <- Ecto.Type.cast(:id, id),
         %Order{} = order <- Repo.one(from o in Order, where: o.id == ^id, lock: "FOR UPDATE") do
      {:ok, order}
    else
      _ -> {:error, :order_not_found}
    end
  end

  defp authorize_sender(associations, player_id) do
    with {:ok, id} <- Ecto.Type.cast(:id, player_id),
         true <- Enum.any?(associations, &(&1.type == "SENDING" and &1.player_id == id)) do
      :ok
    else
      _ -> {:error, :unauthorized}
    end
  end

  defp pending(%Order{state: "PENDING"}), do: :ok
  defp pending(_order), do: {:error, :order_not_pending}

  defp lock_participants(associations, type) do
    senders = Enum.filter(associations, &(&1.type == "SENDING"))
    receivers = Enum.filter(associations, &(&1.type == "RECEIVING"))

    case {type, senders, receivers, length(associations)} do
      {"PLAYER_ORDER", [sender], [receiver], 2}
      when not is_nil(sender.player_id) and not is_nil(receiver.player_id) and
             sender.player_id != receiver.player_id ->
        load_players(sender.player_id, receiver.player_id)

      {"CPU_ORDER", [sender], [], 1} when not is_nil(sender.player_id) ->
        load_players(sender.player_id, nil)

      _ ->
        {:error, :invalid_participants}
    end
  end

  defp load_players(sender_id, receiver_id) do
    players =
      [sender_id, receiver_id]
      |> Enum.reject(&is_nil/1)
      |> Enum.sort()
      |> Enum.map(fn id ->
        Repo.one(from p in Player, where: p.id == ^id, lock: "FOR UPDATE")
      end)

    if Enum.any?(players, &is_nil/1) do
      {:error, :player_not_found}
    else
      sender = Enum.find(players, &(&1.id == sender_id))
      receiver = Enum.find(players, &(&1.id == receiver_id))

      if sender.board_id != nil and (receiver == nil or sender.board_id == receiver.board_id) do
        {:ok, sender, receiver}
      else
        {:error, :invalid_participants}
      end
    end
  end

  defp sufficient_stock(sender, order) do
    if sender.stock >= order.amount, do: :ok, else: {:error, :insufficient_stock}
  end

  defp receive_order(nil, _order), do: {:ok, nil}

  defp receive_order(receiver, order) do
    update_player(receiver, %{stock: receiver.stock + order.amount, last_order: order.amount})
  end

  defp update_player(player, attrs), do: Repo.update(Player.changeset(player, attrs))
end
