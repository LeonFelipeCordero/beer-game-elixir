defmodule BeerGame.Repo.Migrations.CreateBoard do
  use Ecto.Migration

  def change do
    create table(:boards) do
      add :name, :string, null: false
      add :state, :string, default: "RUNNING"
      add :full, :boolean, default: false, null: false
      add :finished, :boolean, default: false, null: false

      timestamps()
    end

    create unique_index(:boards, [:name])
  end
end
