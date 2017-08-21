#!/bin/bash

function setup_oa {
  mkdir -p /var/log/openattic
  mkdir -p /etc/openattic/databases
  mkdir -p /var/lock/openattic

  touch "/var/log/openattic/openattic.log"
  chmod 660 "/var/log/openattic/openattic.log"

  cp /srv/openattic/etc/systemd/* /lib/systemd/system/
  cp /srv/openattic/etc/apache2/conf-available/openattic.conf /etc/apache2/conf-available
  cp /srv/openattic/etc/dbus-1/system.d/openattic.conf /etc/dbus-1/system.d
  cp /srv/openattic/etc/logrotate.d/openattic /etc/logrotate.d
  cp /srv/openattic/etc/init.d/openattic-* /etc/init.d/
  cp /srv/openattic/debian/default/openattic /etc/default
  cp /srv/openattic/debian/database_install/pgsql_template.ini /etc/openattic/databases/pgsql.ini
  ln -s /etc/openattic/databases/pgsql.ini /etc/openattic/database.ini

  # NAGIOS
  cp /srv/openattic/etc/nagios3/conf.d/openattic_static.cfg /etc/nagios3/conf.d
  cp /srv/openattic/etc/nagios3/conf.d/openattic_contacts.cfg /etc/nagios3/conf.d
  cp /srv/openattic/etc/nagios-plugins/config/*.cfg /etc/nagios-plugins/config
  cp /srv/openattic/backend/nagios/plugins/check_diskstats /usr/lib/nagios/plugins
  cp /srv/openattic/backend/nagios/plugins/check_oa_utilization /usr/lib/nagios/plugins
  cp /srv/openattic/backend/nagios/plugins/check_iface_traffic /usr/lib/nagios/plugins
  cp /srv/openattic/backend/nagios/plugins/check_openattic_rpcd /usr/lib/nagios/plugins
  cp /srv/openattic/backend/nagios/plugins/check_openattic_systemd /usr/lib/nagios/plugins
  cp /srv/openattic/backend/nagios/plugins/check_lvm_snapshot /usr/lib/nagios/plugins
  cp /srv/openattic/backend/nagios/plugins/check_cputime /usr/lib/nagios/plugins
  cp /srv/openattic/backend/nagios/plugins/check_protocol_traffic /usr/lib/nagios/plugins
  cp /srv/openattic/backend/nagios/plugins/check_twraid_unit /usr/lib/nagios/plugins
  cp /srv/openattic/backend/nagios/plugins/notify_openattic /usr/lib/nagios/plugins
  cp /srv/openattic/backend/nagios/plugins/check_ceph* /usr/lib/nagios/plugins
  cp -r /srv/openattic/etc/pnp4nagios/check_commands /etc/pnp4nagios/

  # remove *.pyc files
  find /srv/openattic -name '*.pyc' | xargs rm

  sed -i 's!^OADIR=.*!OADIR="/srv/openattic/backend"!' /etc/default/openattic
  sed -i -e 's/^name.*/name = openattic/g' \
         -e 's/^user.*/user = openattic/g' \
         -e 's/^password.*/password = openattic/g' \
         -e 's/^host.*/host = localhost/g' \
         -e 's/^port.*/port = 5432/g' \
         /etc/openattic/databases/pgsql.ini

  sed -i -e 's!/usr/share/openattic!/srv/openattic/backend!g' \
         /etc/apache2/conf-available/openattic.conf
  echo "<Directory /srv/openattic>" >> /etc/apache2/conf-available/openattic.conf
  echo "    Require all granted" >> /etc/apache2/conf-available/openattic.conf
  echo "</Directory>" >> /etc/apache2/conf-available/openattic.conf

  chown -R openattic:openattic /var/log/openattic
  chown -R openattic:openattic /etc/openattic
  chown -R openattic:openattic /var/lock/openattic

  chgrp -R openattic /etc/ceph

  systemd --system &> systemd.log &
  SYSD_PID=$!
  sleep 3
  systemctl daemon-reload
  systemctl start lvm2-lvmetad.socket
  /srv/openattic/bin/oaconfig install --allow-broken-hostname
  a2enconf openattic
  systemctl restart apache2
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

  cp /srv/openattic/etc/systemd/* /lib/systemd/system/
  cp /srv/openattic/etc/apache2/conf-available/openattic.conf /etc/apache2/conf-available
  cp /srv/openattic/etc/dbus-1/system.d/openattic.conf /etc/dbus-1/system.d
  cp /srv/openattic/etc/logrotate.d/openattic /etc/logrotate.d
  cp /srv/openattic/etc/init.d/openattic-* /etc/init.d/
  cp /srv/openattic/debian/default/openattic /etc/default
  cp /srv/openattic/debian/database_install/pgsql_template.ini /etc/openattic/databases/pgsql.ini
  ln -s /etc/openattic/databases/pgsql.ini /etc/openattic/database.ini

  # NAGIOS
  cp /srv/openattic/etc/nagios3/conf.d/openattic_static.cfg /etc/nagios3/conf.d
  cp /srv/openattic/etc/nagios3/conf.d/openattic_contacts.cfg /etc/nagios3/conf.d
  cp /srv/openattic/etc/nagios-plugins/config/*.cfg /etc/nagios-plugins/config
  cp /srv/openattic/backend/nagios/plugins/check_diskstats /usr/lib/nagios/plugins
  cp /srv/openattic/backend/nagios/plugins/check_oa_utilization /usr/lib/nagios/plugins
  cp /srv/openattic/backend/nagios/plugins/check_iface_traffic /usr/lib/nagios/plugins
  cp /srv/openattic/backend/nagios/plugins/check_openattic_rpcd /usr/lib/nagios/plugins
  cp /srv/openattic/backend/nagios/plugins/check_openattic_systemd /usr/lib/nagios/plugins
  cp /srv/openattic/backend/nagios/plugins/check_lvm_snapshot /usr/lib/nagios/plugins
  cp /srv/openattic/backend/nagios/plugins/check_cputime /usr/lib/nagios/plugins
  cp /srv/openattic/backend/nagios/plugins/check_protocol_traffic /usr/lib/nagios/plugins
  cp /srv/openattic/backend/nagios/plugins/check_twraid_unit /usr/lib/nagios/plugins
  cp /srv/openattic/backend/nagios/plugins/notify_openattic /usr/lib/nagios/plugins
  cp /srv/openattic/backend/nagios/plugins/check_ceph* /usr/lib/nagios/plugins
  cp -r /srv/openattic/etc/pnp4nagios/check_commands /etc/pnp4nagios/

  # remove *.pyc files
  find /srv/openattic -name '*.pyc' | xargs rm

  sed -i 's!^OADIR=.*!OADIR="/srv/openattic/backend"!' /etc/default/openattic
  sed -i -e 's/^name.*/name = openattic/g' \
         -e 's/^user.*/user = openattic/g' \
         -e 's/^password.*/password = openattic/g' \
         -e 's/^host.*/host = localhost/g' \
         -e 's/^port.*/port = 5432/g' \
         /etc/openattic/databases/pgsql.ini

  sed -i -e 's!/usr/share/openattic!/srv/openattic/backend!g' \
         /etc/apache2/conf-available/openattic.conf
  echo "<Directory /srv/openattic>" >> /etc/apache2/conf-available/openattic.conf
  echo "    Require all granted" >> /etc/apache2/conf-available/openattic.conf
  echo "</Directory>" >> /etc/apache2/conf-available/openattic.conf

  chown -R openattic:openattic /var/log/openattic
  chown -R openattic:openattic /etc/openattic
  chown -R openattic:openattic /var/lock/openattic

  chgrp -R openattic /etc/ceph

  systemd --system &> systemd.log &
  SYSD_PID=$!
  sleep 3
  systemctl daemon-reload
  systemctl start lvm2-lvmetad.socket
  /srv/openattic/bin/oaconfig install --allow-broken-hostname
  a2enconf openattic
  systemctl stop apache2

  cd /srv/openattic/backend
  python manage.py test -t . -v 2
}


case "$1" in
  setup_oa)
    setup_oa
    ;;
  tests)
    run_oa_tests
    ;;
  *)
    setup_oa
    ;;
esac

