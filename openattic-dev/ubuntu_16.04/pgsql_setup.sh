#!/bin/bash

: ${PGSQL_IP:=*}

function init_pgsql_db {

service postgresql start
su postgres <<'EOF'
psql --command "CREATE USER openattic WITH SUPERUSER PASSWORD 'openattic';"
createdb -O openattic openattic
EOF
service postgresql stop
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" \
       /etc/postgresql/9.5/main/postgresql.conf
echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.5/main/pg_hba.conf
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

