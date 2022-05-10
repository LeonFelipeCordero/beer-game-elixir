defmodule BeerGame.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :amount, :integer, null: false
      add :state, :string, default: "PENDING", null: false
      add :type, :string, null: false

      timestamps()
    end
  end
end
