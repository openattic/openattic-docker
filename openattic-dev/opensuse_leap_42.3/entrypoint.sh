#!/bin/bash

function setup_oa {
  mkdir -p /var/log/openattic
  mkdir -p /etc/openattic/databases
  mkdir -p /var/lock/openattic
  mkdir -p /var/lib/openattic

  touch "/var/log/openattic/openattic.log"
  chmod 660 "/var/log/openattic/openattic.log"

  cp /srv/openattic/etc/systemd/openattic-systemd.service.SUSE /usr/lib/systemd/system/openattic-systemd.service
  cp /srv/openattic/etc/apache2/conf-available/openattic.conf /etc/apache2/conf.d
  cp /srv/openattic/etc/dbus-1/system.d/openattic.conf /etc/dbus-1/system.d
  cp /srv/openattic/etc/logrotate.d/openattic /etc/logrotate.d
  cp /srv/openattic/debian/database_install/pgsql_template.ini /etc/openattic/databases/pgsql.ini
  ln -s /etc/openattic/databases/pgsql.ini /etc/openattic/database.ini

  cp /srv/openattic/rpm/sysconfig/openattic.SUSE /var/adm/fillup-templates/sysconfig.openattic
  cp /srv/openattic/etc/tmpfiles.d/openattic.conf /usr/lib/tmpfiles.d/
  cp /srv/openattic/rpm/sysconfig/openattic.SUSE /etc/sysconfig/openattic

  # remove *.pyc files
  find /srv/openattic -name '*.pyc' | xargs rm

  sed -i 's!^OADIR=.*!OADIR="/srv/openattic/backend"!' /etc/sysconfig/openattic
  sed -i -e 's/^name.*/name = openattic/g' \
         -e 's/^user.*/user = openattic/g' \
         -e 's/^password.*/password = openattic/g' \
         -e 's/^host.*/host = localhost/g' \
         -e 's/^port.*/port = 5432/g' \
         /etc/openattic/databases/pgsql.ini

  sed -i -e 's!/usr/share/openattic!/srv/openattic/backend!g' \
         /etc/apache2/conf.d/openattic.conf
  echo "<Directory /srv/openattic>" >> /etc/apache2/conf.d/openattic.conf
  echo "    Require all granted" >> /etc/apache2/conf.d/openattic.conf
  echo "</Directory>" >> /etc/apache2/conf.d/openattic.conf

  chown -R openattic:openattic /var/log/openattic
  chown -R openattic:openattic /etc/openattic
  chown -R openattic:openattic /var/lock/openattic
  chown -R openattic:openattic /var/lib/openattic

  chgrp -R openattic /etc/ceph
  chmod 644 /etc/ceph/ceph.client.admin.keyring

  systemd --system &> systemd.log &
  SYSD_PID=$!
  sleep 3
  systemctl daemon-reload
  systemctl start apache2
  systemd-tmpfiles --create /usr/lib/tmpfiles.d/openattic.conf
  /srv/openattic/bin/oaconfig install --allow-broken-hostname

  if [[ $1 != "" ]]; then
    sed -i -r "s/#?SALT_API_SHARED_SECRET.*/SALT_API_SHARED_SECRET=\"$1\"/" /etc/sysconfig/openattic
  fi

  chmod 660 /var/log/openattic/openattic.log
  cd /srv/openattic/webui
  touch .chown
  chown openattic .chown &> /dev/null
  CHOWN_RET=$?
  if [ "$CHOWN_RET" == "0" ]; then
    npm install
  else
    runuser -l openattic -c 'cd /srv/openattic/webui && npm install'
  fi
  rm .chown
  npm run dev
}

function run_oa_tests {
  mkdir -p /var/log/openattic
  mkdir -p /etc/openattic/databases
  mkdir -p /var/lock/openattic
  mkdir -p /var/lib/openattic

  cp /srv/openattic/etc/systemd/openattic-systemd.service.SUSE /usr/lib/systemd/system/openattic-systemd.service
  cp /srv/openattic/etc/dbus-1/system.d/openattic.conf /etc/dbus-1/system.d
  cp /srv/openattic/etc/logrotate.d/openattic /etc/logrotate.d
  cp /srv/openattic/debian/database_install/pgsql_template.ini /etc/openattic/databases/pgsql.ini
  ln -s /etc/openattic/databases/pgsql.ini /etc/openattic/database.ini

  cp /srv/openattic/rpm/sysconfig/openattic.SUSE /var/adm/fillup-templates/sysconfig.openattic
  cp /srv/openattic/etc/tmpfiles.d/openattic.conf /usr/lib/tmpfiles.d/
  cp /srv/openattic/rpm/sysconfig/openattic.SUSE /etc/sysconfig/openattic

  # remove *.pyc files
  find /srv/openattic -name '*.pyc' | xargs rm

  sed -i 's!^OADIR=.*!OADIR="/srv/openattic/backend"!' /etc/sysconfig/openattic
  sed -i -e 's/^name.*/name = openattic/g' \
         -e 's/^user.*/user = openattic/g' \
         -e 's/^password.*/password = openattic/g' \
         -e 's/^host.*/host = localhost/g' \
         -e 's/^port.*/port = 5432/g' \
         /etc/openattic/databases/pgsql.ini

  chown -R openattic:openattic /var/log/openattic
  chown -R openattic:openattic /etc/openattic
  chown -R openattic:openattic /var/lock/openattic
  chown -R openattic:openattic /var/lib/openattic

  chgrp -R openattic /etc/ceph

  systemd --system &> systemd.log &
  SYSD_PID=$!
  sleep 3
  systemctl daemon-reload
  systemctl stop apache2
  systemd-tmpfiles --create /usr/lib/tmpfiles.d/openattic.conf
  /srv/openattic/bin/oaconfig install --allow-broken-hostname
  chmod 660 /var/log/openattic/openattic.log
  systemctl stop apache2

  cd /srv/openattic/backend
  coverage run --source='.' manage.py test -t . -v 2
  coverage html
}


case "$1" in
  setup_oa)
    shift
    setup_oa $*
    ;;
  tests)
    run_oa_tests
    ;;
  *)
    setup_oa $*
    ;;
esac

