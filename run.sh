#!/bin/sh

set -e

mix deps.get

# Set up database and run migrations
mix ecto.create
mix ecto.migrate

#if secret is not in .env, generates a new one
if [ -z "$SECRET_KEY_BASE" ]
then
    echo ""
    echo "Secret not found in .env file. Generating a secret..."
    echo ""
    export SECRET_KEY_BASE=$(mix phx.gen.secret)
    echo "SECRET >> ${SECRET_KEY_BASE}"
    echo "Copy this value to your .env file."
    echo ""
fi

# Test if installation is OK
#echo "Testing the installation..."
#mix test

#Start Phoenix Server if everything is OK
echo "Launching Phoenix web server..."
mix phx.server
