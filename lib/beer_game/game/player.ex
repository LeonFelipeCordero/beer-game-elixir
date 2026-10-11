defmodule BeerGame.Game.Player do
  use Ecto.Schema
  import Ecto.Changeset

  schema "players" do
    field :name, :string
    field :role, :string
    field :backlog, :integer
    field :last_order, :integer, source: :lastOrder
    field :weekly_orders, :integer, source: :weeklyOrders
    field :stock, :integer
    field :cpu, :boolean

    belongs_to :board, BeerGame.Game.Board
    has_many :player_orders, BeerGame.Game.PlayerOrders
    has_many :orders, through: [:player_orders, :order]

    timestamps()
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:name, :role, :stock, :backlog, :weekly_orders, :last_order])
    |> validate_required([:name, :role, :stock, :backlog, :weekly_orders, :last_order])
  end
end
