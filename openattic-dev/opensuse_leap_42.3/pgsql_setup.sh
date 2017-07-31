#!/bin/bash


function init_pgsql_db {
  mkdir -p /var/lib/pgsql
  chown -R postgres:postgres /var/lib/pgsql

su postgres <<'EOF'
/usr/lib/postgresql-init start
psql --command "CREATE USER openattic WITH SUPERUSER PASSWORD 'openattic';"
createdb -O openattic openattic
echo "host all  all    0.0.0.0/0  md5" > /var/lib/pgsql/data/pg_hba.conf
echo "local all  all    trust" >> /var/lib/pgsql/data/pg_hba.conf
echo "host all  all  ::1/128  md5" >> /var/lib/pgsql/data/pg_hba.conf
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" \
    /var/lib/pgsql/data/postgresql.conf
EOF
}

function start_pgsql_db {
  su postgres -c '/usr/lib/postgresql/9.5/bin/pg_ctl start -D /var/lib/pgsql/data'

  PG_PID=`pgrep postgres | head -1`
  while [ -e /proc/${PG_PID} ]; do sleep 2;done
}

case "$1" in
  init_db)
    init_pgsql_db
    ;;
  start_db | *)
    start_pgsql_db
    ;;
esac

