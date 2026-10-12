FROM elixir:1.20.4-otp-29-slim AS base
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*

FROM base AS build
ENV MIX_ENV=prod
WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force
COPY mix.exs mix.lock ./
COPY config ./config
RUN mix deps.get --only prod && mix deps.compile

COPY assets ./assets
COPY lib ./lib
COPY priv ./priv
RUN mix compile --warnings-as-errors && mix assets.deploy && mix release

FROM base

WORKDIR /app
ENV PHX_SERVER=true
COPY --from=build --chown=nobody:nogroup /app/_build/prod/rel/beer_game ./
USER nobody
EXPOSE 4000
CMD ["sh", "-c", "bin/beer_game eval 'BeerGame.Release.migrate()' && exec bin/beer_game start"]
