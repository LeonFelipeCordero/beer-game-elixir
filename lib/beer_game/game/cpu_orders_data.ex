defmodule BeerGame.Game.CpuOrderData do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cpu_orders_data" do
    field :amount, :integer
    belongs_to :player, BeerGame.Game.Player

    timestamps()
  end

  @doc false
  def changeset(line_item, attrs) do
    line_item
    |> cast(attrs, [:amount])
    |> validate_required([:amount])
  end
end
