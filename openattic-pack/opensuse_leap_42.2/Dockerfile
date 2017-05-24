# OpenATTIC Packaging docker image

FROM opensuse:42.2
MAINTAINER Ricardo Dias "rdias@suse.com"

ADD entrypoint.sh /

RUN zypper ar http://download.opensuse.org/repositories/filesystems:/openATTIC/openSUSE_Leap_42.2 oa_repo
RUN zypper --gpg-auto-import-keys ref && \
zypper -n install git nodejs npm python-docopt which tar osc build sudo && \
zypper clean -a

RUN npm install -g bower
RUN npm install -g grunt-cli

VOLUME ["/srv/openattic"]

ENTRYPOINT ["/entrypoint.sh"]
