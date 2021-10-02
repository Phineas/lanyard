FROM elixir:1.12.3-alpine AS build

ENV MIX_ENV=prod

WORKDIR /app

# get deps first so we have a cache
ADD mix.exs mix.lock /app/
RUN \
cd /app && \
mix local.hex --force && \
mix local.rebar --force && \
mix deps.get

# then make a release build
ADD . /app/
RUN \
mix compile && \
mix release

FROM elixir:1.12.3-alpine

COPY --from=build /app/_build/prod/rel/lanyard /opt/lanyard

CMD [ "/opt/lanyard/bin/lanyard", "start" ]
