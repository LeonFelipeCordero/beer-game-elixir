defmodule BeerGame.Game.Board do
  use Ecto.Schema
  import Ecto.Changeset

  schema "boards" do
    field :name, :string
    field :state, :string, default: "running"
    field :full, :boolean, default: false
    field :finished, :boolean, default: false

    has_many :players, BeerGame.Game.Player

    timestamps()
  end

  @doc false
  def changeset(board, attrs) do
    board
    |> cast(attrs, [:name, :state, :full, :finished])
    |> validate_required([:name, :state, :full, :finished])
  end
end
