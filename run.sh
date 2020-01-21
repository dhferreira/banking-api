#!/bin/sh

set -e

mix deps.get

# Set up database and run migrations
mix ecto.create
mix ecto.migrate

# Test if installation is OK
#echo "Testing the installation..."
#mix test

#Start Phoenix Server if everything is OK
echo "Launching Phoenix web server..."
mix phx.server
