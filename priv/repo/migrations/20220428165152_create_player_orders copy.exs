defmodule BeerGame.Repo.Migrations.CreatePlayerOrders do
  use Ecto.Migration

  def change do
    create table(:player_orders) do
      add :type, :string, null: false
      add :player_id, references(:players, on_delete: :delete_all)
      add :order_id, references(:orders, on_delte: :delete_all)

      timestamps()
    end

    create index(:player_orders, [:player_id])
    create index(:player_orders, [:order_id])
  end
end
