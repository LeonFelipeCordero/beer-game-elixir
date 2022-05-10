defmodule BeerGame.GameFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BeerGame.Game` context.
  """

  @doc """
  Generate a player.
  """
  def player_fixture(attrs \\ %{}) do
    {:ok, player} =
      attrs
      |> Enum.into(%{
        backlog: "some backlog",
        lastOrder: "some lastOrder",
        name: "some name",
        role: "some role",
        stock: "some stock",
        weeklyOrders: "some weeklyOrders"
      })

    player
  end

  @doc """
  Generate a board.
  """
  def board_fixture(attrs \\ %{}) do
    {:ok, board} =
      attrs
      |> Enum.into(%{
        full: true,
        state: "some state"
      })
      |> BeerGame.Game.create_board()

    board
  end

  @doc """
  Generate a retailer_order.
  """
  def retailer_order_fixture(attrs \\ %{}) do
    {:ok, retailer_order} =
      attrs
      |> Enum.into(%{
        amount: 42,
        state: true
      })
      |> BeerGame.Game.create_retailer_order()

    retailer_order
  end

  @doc """
  Generate a wholesaler_order.
  """
  def wholesaler_order_fixture(attrs \\ %{}) do
    {:ok, wholesaler_order} =
      attrs
      |> Enum.into(%{
        amount: 42,
        state: "some state"
      })
      |> BeerGame.Game.create_wholesaler_order()

    wholesaler_order
  end

  @doc """
  Generate a factory_order.
  """
  def factory_order_fixture(attrs \\ %{}) do
    {:ok, factory_order} =
      attrs
      |> Enum.into(%{
        amount: 42,
        state: "some state"
      })
      |> BeerGame.Game.create_factory_order()

    factory_order
  end

  @doc """
  Generate a order.
  """
  def order_fixture(attrs \\ %{}) do
    {:ok, order} =
      attrs
      |> Enum.into(%{
        amount: 42,
        contrapart_id: "some contrapart_id",
        state: "some state"
      })
      |> BeerGame.Game.create_order()

    order
  end
end
