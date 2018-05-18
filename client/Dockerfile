FROM krallin/centos-tini:7
MAINTAINER Michael J. Stealey <michael.j.stealey@gmail.com>

RUN rpmkeys --import file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    yum -y --setopt=tsflags=nodocs install nfs-utils && \
    yum clean all

ENV NFS_SERVER=server \
  NFS_SERVER_DIRS='/nfs/share' \
  NFS_CLIENT_DIRS='/mnt/share'

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/tini", "--", "/docker-entrypoint.sh"]
