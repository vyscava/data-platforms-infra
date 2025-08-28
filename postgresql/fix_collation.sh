#!/bin/sh
set -e
until pg_isready -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d postgres >/dev/null 2>&1; do
  echo "Waiting for Postgres at $PGHOST:$PGPORT ..."
  sleep 1
done

psql -AtqX -d postgres -c "SELECT datname
                           FROM pg_database
                           WHERE datallowconn AND datname NOT IN ('template0','template1');" \
| while IFS= read -r db; do
  [ -n "$db" ] || continue
  echo "Checking $db ..."
  MISMATCH=$(psql -AtqX -d "$db" -c "
    SELECT (SELECT datcollversion FROM pg_database WHERE datname = current_database()) IS DISTINCT FROM
           (SELECT collversion FROM pg_collation WHERE collname = 'default');")
  if [ "$MISMATCH" = "t" ]; then
    echo "  -> Collation mismatch detected in $db. Reindexing..."
    psql -X -d "$db" -c "REINDEX DATABASE CONCURRENTLY \"$db\";"
    psql -X -d "$db" -c "ALTER DATABASE \"$db\" REFRESH COLLATION VERSION;"
    echo "  -> $db fixed."
  else
    echo "  -> $db OK."
  fi
done