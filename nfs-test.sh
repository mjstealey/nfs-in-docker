#!/usr/bin/env bash

echo "### NFS test ###"
# write content from server
echo; echo "### write on server ###"
echo "$ touch /nfs/home/server-touch-home"
docker exec server touch /nfs/home/server-touch-home
echo "$ touch /nfs/secret/server-touch-secret"
docker exec server touch /nfs/secret/server-touch-secret
echo "$ touch /nfs/modules/server-touch-modules"
docker exec server touch /nfs/modules/server-touch-modules
echo "$ touch /nfs/modulefiles/server-touch-modulefiles"
docker exec server touch /nfs/modulefiles/server-touch-modulefiles

# read content from client
echo; echo "### read from client ###"
echo "$ ls -l /home"
docker exec client ls -l /home
echo "$ ls -l /secret"
docker exec client ls -l /secret
echo "$ ls -l /opt/apps/Linux"
docker exec client ls -l /opt/apps/Linux
echo "$ ls -l /opt/apps/modulefiles/Linux"
docker exec client ls -l /opt/apps/modulefiles/Linux

# write content from client
echo; echo "### write on client ###"
echo "$ touch /home/client-touch-home"
docker exec client touch /home/client-touch-home
echo "$ touch /secret/client-touch-secret"
docker exec client touch /secret/client-touch-secret
echo "$ client touch /opt/apps/Linux/client-touch-modules"
docker exec client touch /opt/apps/Linux/client-touch-modules
echo "$ touch /opt/apps/modulefiles/Linux/client-touch-modulefiles"
docker exec client touch /opt/apps/modulefiles/Linux/client-touch-modulefiles

# read content from server
echo; echo "### read from client ###"
echo "$ ls -l /nfs/home"
docker exec server ls -l /nfs/home
echo "$ ls -l /nfs/secret"
docker exec server ls -l /nfs/secret
echo "$ ls -l /nfs/modules"
docker exec server ls -l /nfs/modules
echo "$ ls -l /nfs/modulefiles"
docker exec server ls -l /nfs/modulefiles

# create new user on client
echo; echo "### create user=worker, gid=1000, uid=1000 from client ###"
CMD="groupadd --gid 1000 worker && useradd  -m -c \"Workflow user\" -d /home/worker --uid 1000 -g worker  -s /bin/bash worker"
echo "$ ${CMD}"
docker exec client bash -c "${CMD}"
echo; echo "### read from client ###"
echo "$ ls -l /home"
docker exec client ls -l /home
echo; echo "### read from server ###"
echo "$ ls -l /nfs/home"
docker exec server ls -l /nfs/home

exit 0;
