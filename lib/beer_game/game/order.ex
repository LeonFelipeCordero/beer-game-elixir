defmodule BeerGame.Game.Order do
  use Ecto.Schema
  import Ecto.Changeset

  schema "orders" do
    field :amount, :integer
    field :state, :string
    field :type, :string

    timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:amount, :state, :type])
    |> validate_required([:amount, :type])
  end
end
