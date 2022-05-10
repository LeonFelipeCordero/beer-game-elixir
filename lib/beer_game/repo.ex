defmodule BeerGame.Repo do
  use Ecto.Repo,
    otp_app: :beer_game,
    adapter: Ecto.Adapters.MyXQL
end
