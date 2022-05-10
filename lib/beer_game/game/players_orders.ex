defmodule BeerGame.Game.PlayerOrders do
  use Ecto.Schema
  import Ecto.Changeset

  schema "player_orders" do
    field :type, :string

    belongs_to :player, BeerGame.Game.Player
    belongs_to :order, BeerGame.Game.Order

    timestamps()
  end

  @doc false
  def changeset(line_item, attrs) do
    line_item
    |> cast(attrs, [:type])
    |> validate_required([:type])
  end
end
