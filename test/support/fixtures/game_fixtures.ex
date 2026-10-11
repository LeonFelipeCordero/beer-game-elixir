defmodule BeerGame.GameFixtures do
  alias BeerGame.{Boards, Orders}

  def board_fixture(attrs \\ %{}) do
    {:ok, board} =
      attrs
      |> Enum.into(%{name: "board-#{System.unique_integer([:positive])}"})
      |> Boards.create_board()

    board
  end

  def player_fixture(board, role \\ "retailer") do
    {:ok, player} = Boards.create_player_by_role(role, board)
    player
  end

  def order_fixture(attrs \\ %{}) do
    {:ok, order} =
      attrs
      |> Enum.into(%{amount: 4, type: "PLAYER_ORDER", state: "PENDING"})
      |> Orders.create_order()

    order
  end

  def player_order_fixture(order, player, type) do
    {:ok, player_order} = Orders.create_player_order(%{type: type}, order, player)
    player_order
  end
end
