FROM elixir:latest

RUN ["mix", "local.hex", "--force"]

WORKDIR /app

COPY . /app/

EXPOSE 4000

RUN ["mix", "deps.get"]
RUN ["mix", "local.rebar", "--force"]
RUN ["mix", "phx.gen.secret"]

CMD [ "mix", "phx.server" ]