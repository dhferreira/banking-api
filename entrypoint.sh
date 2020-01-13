#!/bin/bash
while ! pg_isready -q -h $PGHOST -p $PGPORT -U $PGUSER
do
  echo "Waiting for database"
  sleep 2
done

if ! (psql -lqtA | grep -q "^$PGDATABASE|"); then
  echo "database $PGDATABASE does not exist. Creating..."
  #createdb -E UTF8 $PGDATABASE -l en_US.UTF-8 -T template0

  mix ecto.create

  echo "Database $PGDATABASE created."
fi

mix ecto.migrate
#exec mix ecto.migrate

exec mix phx.server