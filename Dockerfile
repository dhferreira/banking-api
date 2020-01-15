FROM elixir:alpine

RUN apk update && \
  apk add gcc g++ make

# Install Phoenix packages
RUN mix local.hex --force
RUN mix local.rebar --force
RUN wget https://github.com/phoenixframework/archives/raw/master/phx_new.ez
RUN mix archive.install phx_new.ez --force

WORKDIR /app

EXPOSE 4000
