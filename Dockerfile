FROM elixir:1.14-alpine AS build

RUN apk add git

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

FROM elixir:1.14-alpine

RUN apk add redis

COPY --from=build /app/_build/prod/rel/lanyard /opt/lanyard

CMD [ "/opt/lanyard/bin/lanyard", "start" ]
