# OpenATTIC Dev docker image

FROM opensuse:42.2
MAINTAINER Ricardo Dias "rdias@suse.com"

ADD entrypoint.sh pgsql_setup.sh /

RUN zypper ar http://download.opensuse.org/repositories/filesystems:/openATTIC/openSUSE_Leap_42.2 oa_repo
RUN zypper ar http://download.opensuse.org/repositories/filesystems/openSUSE_Leap_42.2 zfs_repo
RUN zypper --gpg-auto-import-keys ref && \
zypper -n install --force-resolution krb5 && \
zypper -n install --force-resolution e2fsprogs && \
zypper -n install mercurial git nodejs npm bridge-utils bzip2 dbus-1 systemd \\
python-django=1.6.11 \\
python-django-filter python-djangorestframework python-djangorestframework-bulk python-M2Crypto memcached \\
apache2-mod_wsgi ntp numpy policycoreutils-python python-gobject2 dbus-1-python python-configobj \\
python-django python-imaging python-m2ext python-memcached python-netaddr \\
python-netifaces python-pam python-psycopg2 python-pyudev python-requests \\
python-simplejson selinux-tools policycoreutils btrfsprogs python-rtslib \\
udisks2 wget xfsprogs net-tools apache2 policycoreutils-python  \\
python-rados ceph-common cronie lvm2 bc nagios icinga python-coverage \\
pnp4nagios nagios-plugins-http nagios-plugins-swap nagios-plugins-ssh \\
nagios-plugins-ping nagios-plugins-disk nagios-plugins-users nagios-plugins-procs \\
nagios-plugins-load nagios-plugins-tcp nfs-utils cron postgresql-server \\
postgresql vlan shadow smtp_daemon samba python-mock zfs && \\
zypper clean -a

RUN (cd /usr/lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /usr/lib/systemd/system/multi-user.target.wants/*;\
rm -f /usr/etc/systemd/system/*.wants/*;\
rm -f /usr/lib/systemd/system/local-fs.target.wants/*; \
rm -f /usr/lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /usr/lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /usr/lib/systemd/system/basic.target.wants/*;\
rm -f /usr/lib/systemd/system/anaconda.target.wants/*;

RUN npm install -g bower
RUN npm install -g grunt-cli

RUN /pgsql_setup.sh init_db

RUN groupadd -r openattic; usermod -a --groups openattic wwwrun; \\
useradd -r -g openattic -d /var/lib/openattic -s /bin/bash -c "openATTIC System User" openattic; \\
usermod -a --groups openattic icinga; usermod -a -G openattic icinga; \\
usermod -a --groups icinga,nagcmd,www openattic

EXPOSE 5432 80

VOLUME ["/srv/openattic", "/sys/fs/cgroup", "/etc/ceph"]

ENTRYPOINT ["/entrypoint.sh"]
