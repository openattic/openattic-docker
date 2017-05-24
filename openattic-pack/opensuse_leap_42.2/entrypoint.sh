#!/bin/bash

cd /srv/openattic
./utils/make_dist.py create release --destination=/tmp --revision=master -v

cd /tmp
osc -A $1 co $2 $3
mv openattic*.tar.bz2 $2/$3
cd $2/$3
VER=`cat /srv/openattic/version.txt | grep VERSION | sed 's/VERSION = \(.*\)/\1/g'`
tar -xvf openattic-${VER}.tar.bz2 openattic-${VER}/rpm/openattic.spec.SUSE
cp openattic-${VER}/rpm/openattic.spec.SUSE openattic.spec
sed -i -e "s/^Version:.*/Version: $VER/g" openattic.spec
osc -A $1 build
DISTRO=`ls /var/tmp/build-root/`
mkdir -p /srv/openattic/packages/$DISTRO
for f in `find /var/tmp/build-root -name '*.rpm'`; do
  cp $f /srv/openattic/packages/$DISTRO/
done

