#!/bin/bash
set -e

_init_fstab() {
  if [[ ! -f /etc/fstab ]]; then
    cat > /etc/fstab << EOF
### <server>:</remote/export> </local/directory> <nfs-type> <options> 0 0
EOF
  fi
}

_export_nfs_mounts() {
  IFS=':' read -r -a MNT_SERVER_ARRAY <<< "$NFS_SERVER_DIRS"
  IFS=':' read -r -a MNT_CLIENT_ARRAY <<< "$NFS_CLIENT_DIRS"
  for i in "${!MNT_CLIENT_ARRAY[@]}"; do
    if [[ ! -d ${MNT_CLIENT_ARRAY[$i]} ]]; then
      mkdir -p ${MNT_CLIENT_ARRAY[$i]}
    fi
    cat >> /etc/fstab <<EOF
${NFS_SERVER}:${MNT_SERVER_ARRAY[$i]} ${MNT_CLIENT_ARRAY[$i]} nfs rw,hard,intr 0 0
EOF
  done
  cat /etc/fstab
}

### main ###
rpcbind
rpc.nfsd
echo "connecting to ${NFS_SERVER}"
until [ $(ping ${NFS_SERVER} -c 3 2>&1 >/dev/null)$? ]; do
  echo -n "."
  sleep 1
done

_init_fstab
_export_nfs_mounts
mount -a

rpcinfo -p $NFS_SERVER
showmount -e $NFS_SERVER

tail -f /dev/null
