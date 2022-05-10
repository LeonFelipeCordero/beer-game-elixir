defmodule BeerGame.Repo.Migrations.CpuOrdersData do
  use Ecto.Migration

  def change do
    create table(:cpu_orders_data) do
      add :amount, :integer, null: false
      add :player_id, references(:players, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:cpu_orders_data, [:player_id])
  end
end
