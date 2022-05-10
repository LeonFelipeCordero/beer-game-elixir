defmodule BeerGame.Repo.Migrations.CreatePlayer do
  use Ecto.Migration

  def change do
    create table(:players) do
      add :name, :string, null: false
      add :role, :string, null: false
      add :stock, :integer, null: false
      add :backlog, :integer, null: false
      add :weeklyOrders, :integer, null: false
      add :lastOrder, :integer, null: false
      add :cpu, :boolean, null: false

      add :board_id, references(:boards, on_delete: :nothing)

      timestamps()
    end
  end
end
