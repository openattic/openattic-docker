#!/bin/bash

: ${PGSQL_IP:=*}

function setup_oa {
  mkdir -p /var/log/openattic
  mkdir -p /etc/openattic/databases
  mkdir -p /var/lock/openattic
  mkdir -p /var/lib/openattic

  cp /srv/openattic/etc/systemd/* /usr/lib/systemd/system/
  cp /srv/openattic/etc/apache2/conf-available/openattic.conf /etc/apache2/conf.d
  cp /srv/openattic/etc/apache2/conf-available/openattic-volumes.conf /etc/apache2/conf.d
  cp /srv/openattic/etc/cron.d/updatetwraid /etc/cron.d
  cp /srv/openattic/etc/dbus-1/system.d/openattic.conf /etc/dbus-1/system.d
  cp /srv/openattic/etc/logrotate.d/openattic /etc/logrotate.d
  cp /srv/openattic/debian/database_install/pgsql_template.ini /etc/openattic/databases/pgsql.ini
  ln -s /etc/openattic/databases/pgsql.ini /etc/openattic/database.ini

  cp /srv/openattic/rpm/sysconfig/openattic.SUSE /var/adm/fillup-templates/sysconfig.openattic
  cp /srv/openattic/etc/tmpfiles.d/openattic.conf /usr/lib/tmpfiles.d/
  cp /srv/openattic/rpm/sysconfig/openattic.SUSE /etc/sysconfig/openattic


cat > /etc/default/openattic <<EOF
PYTHON="/usr/bin/python"
OADIR="/srv/openattic/backend"

RPCD_PIDFILE="/var/run/openattic_rpcd.pid"
RPCD_CHUID="openattic:openattic"
RPCD_LOGFILE="/var/log/openattic/openattic_rpcd.log"
RPCD_LOGLEVEL="INFO"
RPCD_OPTIONS="$OADIR/manage.py runrpcd"
RPCD_CERTFILE=""
RPCD_KEYFILE=""

SYSD_PIDFILE="/var/run/openattic_systemd.pid"
SYSD_LOGFILE="/var/log/openattic/openattic_systemd.log"
SYSD_LOGLEVEL="INFO"
SYSD_OPTIONS="$OADIR/manage.py runsystemd"

WEBSERVER_SERVICE="apache2"
SAMBA_SERVICES="smb nmb"
WINBIND_SERVICE="winbind"

NAGIOS_CFG="/etc/nagios/nagios.cfg"
NAGIOS_STATUS_DAT="/var/log/nagios/status.dat"
NAGIOS_SERVICE="nagios"
NPCD_MOD="/usr/lib64/npcdmod.o"
NPCD_CFG="/etc/pnp4nagios/npcd.cfg"
NPCD_SERVICE="npcd"
#NAGIOS_SERVICES_CFG_PATH="/etc/icinga/objects"
EOF

  # NAGIOS
  cp /srv/openattic/etc/nagios-plugins/config/openattic.cfg /etc/icinga/objects/openattic_plugins.cfg
  echo >> /etc/icinga/objects/openattic_plugins.cfg
  cat /srv/openattic/etc/nagios-plugins/config/openattic-ceph.cfg >> /etc/icinga/objects/openattic_plugins.cfg

  cp /srv/openattic/etc/nagios3/conf.d/openattic_*.cfg /etc/icinga/objects/

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

  sed -i '/^# You can specify individual object/a \
cfg_file=/etc/icinga/objects/openattic_plugins.cfg\
cfg_file=/etc/icinga/objects/openattic_static.cfg' \
       /etc/icinga/icinga.cfg

  chown -R openattic:openattic /var/log/openattic
  chown -R openattic:openattic /etc/openattic
  chown -R openattic:openattic /var/lock/openattic
  chown -R openattic:openattic /var/lib/openattic

  chgrp -R openattic /etc/ceph

  systemd --system &> systemd.log &
  SYSD_PID=$!
  sleep 3
  sed -i -e 's/#master: salt/master: localhost/' /etc/salt/minion
  sed -i -e 's/^Type=notify/Type=simple/' -e 's/^Notify*//' /usr/lib/systemd/system/salt-minion.service
  systemctl daemon-reload
  systemctl start apache2
  systemctl start icinga
  systemctl start npcd
  systemd-tmpfiles --create /usr/lib/tmpfiles.d/openattic.conf
  systemctl start lvm2-lvmetad.socket
  systemctl start salt-master
  sleep 2
  systemctl start salt-minion
  sleep 5
  salt-key -Ay

  cd /srv/deepsea
  if [[ -e Makefile ]]; then
    make install
    sed -i "s/_REPLACE_ME_/`hostname -f`/" /srv/pillar/ceph/master_minion.sls
    chown -R salt:salt /srv/pillar
    systemctl restart salt-master
    sleep 2
    salt-run state.orch ceph.stage.prep
    sleep 2
    salt-run state.orch ceph.stage.discovery
cat > /srv/pillar/ceph/proposals/policy.cfg <<EOF
# Cluster assignment
cluster-ceph/cluster/*.sls
# Hardware Profile
profile-*-1/cluster/*.sls
profile-*-1/stack/default/ceph/minions/*yml
# Common configuration
config/stack/default/global.yml
config/stack/default/ceph/cluster.yml
# Role assignment
role-master/cluster/*.sls
role-mon/cluster/*.sls
role-igw/cluster/*.sls
role-mon/stack/default/ceph/minions/*.yml
EOF
    chown salt:salt /srv/pillar/ceph/proposals/policy.cfg
    sleep 2
    salt-run state.orch ceph.stage.configure
  fi

  /srv/openattic/bin/oaconfig install --allow-broken-hostname
  chmod 660 /var/log/openattic/openattic.log
  cd /srv/openattic/webui
  npm install
  bower install --allow-root
  grunt dev
}

case "$1" in
  setup_oa | *)
    setup_oa
    ;;
esac

