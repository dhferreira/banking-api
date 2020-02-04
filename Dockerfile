FROM elixir:1.9.4-alpine as build

# install build dependencies
RUN apk add --update git build-base nodejs yarn python

# prepare build dir
RUN mkdir /app
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
# !!!! UPDATE SECRET WITH YOUR SECRET mix phx.gen.secret !!!!
ENV MIX_ENV=prod
ENV SECRET_KEY_BASE=

RUN env

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only prod
RUN mix deps.compile

# build assets
COPY priv priv
RUN mix phx.digest

# build project
COPY lib lib
RUN mix compile

# build release
RUN mix release

# prepare release image
FROM alpine:3.9 AS app
RUN apk add --update bash openssl

RUN mkdir /app
WORKDIR /app

COPY --from=build /app/_build/prod/rel/banking_api ./
RUN chown -R nobody: /app
USER nobody

ENV HOME=/app
