# NFS in Docker

**WORK IN PROGRESS**

NFS version 3 server and client in docker.

## About

Definitions for both an NFS server and client have been defined using CentOS 7 as the base. Using docker-compose to coordinate two node demonstration.

Volumes served by the NFS server can be defined as host volume mounts, or reside strictly inside the docker container. Volumes are mounted at runtime based on environment variables passed into the container.

## Environment variables

### Server

### `RPCNFSDCOUNT`

nfsd threads - number of nfsd threads to use. Default `=8`.

### `NFS_SERVER_DIRS`

NSF mounts - full path for server side NFS volumes, as seen by the container, that will be serviced. Default `='/nfs/share'`. All volumes should begin with `/nfs` and a semicolon (`:`) should be used between each path definition.

### Client

### `NFS_SERVER`

FQDN or IP - of the NFS server. Default `=server`.

### `NFS_SERVER_DIRS`

Volumes as provided from the NFS server. Default `='/nfs/share'`.

### `NFS_CLIENT_DIRS`

Volumes to mount on the client. Default `='/mnt/share'`. Must be an in order correlation to the volumes as defined in `NFS_SERVER_DIRS` as that is the order they will be mounted in. Example: `mount ${NFS_SERVER}:${NFS_SERVER_DIRS[0]} ${NFS_CLIENT_DIRS[0]}`

## Preliminary setup

### docker volume

Due to differences in permissions in how macOS and Linux treat host mounted volumes, a docker volume will be defined for use by the primary NFS export directory, and bound to the server container.

### Linux

Create directory named **nfs** and create a docker volume with it:

```
mkdir nfs
docker volume create \
  --name nfs \
  --opt type=tmpfs \
  --opt device=$(pwd)/nfs \
  --opt o=bind
```

Verify creation of volume:

```
[
    {
        "CreatedAt": "2018-05-18T12:19:20-04:00",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/lib/docker/volumes/nfs/_data",
        "Name": "nfs",
        "Options": {
            "device": "/home/$USER/nfs-in-docker/nfs",
            "o": "bind",
            "type": "tmpfs"
        },
        "Scope": "local"
    }
]
```

Viewing the contents of the volume: Since the Linux volume is bound to the host, we can simply observe the contents using `ls`.

```
ls -lR nfs
```

### macOS

Create docker volume named **nfs**:

```
docker volume create \
  --name nfs \
  --driver local \
  --opt type=tmpfs \
  --opt device=tmpfs
```

Verify creation of volume:

```console
$ docker volume inspect nfs
[
    {
        "CreatedAt": "2018-05-18T16:09:05Z",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/lib/docker/volumes/nfs/_data",
        "Name": "nfs",
        "Options": {
            "device": "tmpfs",
            "type": "tmpfs"
        },
        "Scope": "local"
    }
]
```

Viewing the contents of the volume: Run this from your Mac terminal and it'll drop you in a container with full permissions on the Moby VM. This also works for Docker for Windows for getting in Moby Linux VM (doesn't work for Windows Containers).

```
docker run -it --rm --privileged --pid=host justincormack/nsenter1
```

List docker's volumes

```
ls /var/lib/docker/volumes
```

more info: [https://github.com/justincormack/nsenter1](https://github.com/justincormack/nsenter1)

## Start the `docker-compose.yml` file

A [docker-compose.yml](docker-compose.yml) file has been provided to create the two node server and client network for demonstration.

```console
$ docker-compose up -d
Creating client ... done
Creating server ... done
```

Once run the user should observe two new containers

```console
$ docker-compose ps
 Name               Command               State         Ports
-------------------------------------------------------------------
client   /usr/local/bin/tini -- /do ...   Up
server   /usr/local/bin/tini -- /do ...   Up      111/udp, 2049/tcp
```

At this point the NFS server container should be serving four directories to the NFS client container.

From the `server`:

```console
$ docker exec server cat /etc/exports
/nfs/secret *(rw,sync,no_subtree_check,no_root_squash,fsid=272)
/nfs/home *(rw,sync,no_subtree_check,no_root_squash,fsid=281)
/nfs/modules *(rw,sync,no_subtree_check,no_root_squash,fsid=238)
/nfs/modulefiles *(rw,sync,no_subtree_check,no_root_squash,fsid=250)
```


From the `client`:

```console
$ docker exec client showmount -e server
Export list for server:
/nfs/modulefiles *
/nfs/modules     *
/nfs/home        *
/nfs/secret      *
$ docker exec client cat /etc/fstab
### <server>:</remote/export></local/directory><nfs-type><options> 0 0
server:/nfs/secret /secret nfs rw 0 0
server:/nfs/home /home nfs rw 0 0
server:/nfs/modules /opt/apps/Linux nfs rw 0 0
server:/nfs/modulefiles /opt/apps/modulefiles/Linux nfs rw 0 0
```

The directories should all initially be empty (example using Linux volume mount).

```console
$ ls -lR nfs
nfs:
total 0
drwxrwxrwx 2 root root 6 May 18 13:37 home
drwxrwxrwx 2 root root 6 May 18 13:37 modulefiles
drwxrwxrwx 2 root root 6 May 18 13:37 modules
drwxrwxrwx 2 root root 6 May 18 13:37 secret

nfs/home:
total 0

nfs/modulefiles:
total 0

nfs/modules:
total 0

nfs/secret:
total 0
```

## Test with `nfs-test.sh`

A script named [nfs-test.sh](nfs-test.sh) has been provided to test the NFS mounts.

```console
$ ./nfs-test.sh
### NFS test ###

### write on server ###
$ touch /nfs/home/server-touch-home
$ touch /nfs/secret/server-touch-secret
$ touch /nfs/modules/server-touch-modules
$ touch /nfs/modulefiles/server-touch-modulefiles

### read from client ###
$ ls -l /home
total 0
-rw-r--r-- 1 root root 0 May 18 17:45 server-touch-home
$ ls -l /secret
total 0
-rw-r--r-- 1 root root 0 May 18 17:45 server-touch-secret
$ ls -l /opt/apps/Linux
total 0
-rw-r--r-- 1 root root 0 May 18 17:45 server-touch-modules
$ ls -l /opt/apps/modulefiles/Linux
total 0
-rw-r--r-- 1 root root 0 May 18 17:45 server-touch-modulefiles

### write on client ###
$ touch /home/client-touch-home
$ touch /secret/client-touch-secret
$ client touch /opt/apps/Linux/client-touch-modules
$ touch /opt/apps/modulefiles/Linux/client-touch-modulefiles

### read from client ###
$ ls -l /nfs/home
total 0
-rw-r--r-- 1 root root 0 May 18 17:45 client-touch-home
-rw-r--r-- 1 root root 0 May 18 17:45 server-touch-home
$ ls -l /nfs/secret
total 0
-rw-r--r-- 1 root root 0 May 18 17:45 client-touch-secret
-rw-r--r-- 1 root root 0 May 18 17:45 server-touch-secret
$ ls -l /nfs/modules
total 0
-rw-r--r-- 1 root root 0 May 18 17:45 client-touch-modules
-rw-r--r-- 1 root root 0 May 18 17:45 server-touch-modules
$ ls -l /nfs/modulefiles
total 0
-rw-r--r-- 1 root root 0 May 18 17:45 client-touch-modulefiles
-rw-r--r-- 1 root root 0 May 18 17:45 server-touch-modulefiles

### create user=worker, gid=1000, uid=1000 from client ###
$ groupadd --gid 1000 worker && useradd  -m -c "Workflow user" -d /home/worker --uid 1000 -g worker  -s /bin/bash worker

### read from client ###
$ ls -l /home
total 0
-rw-r--r-- 1 root   root    0 May 18 17:45 client-touch-home
-rw-r--r-- 1 root   root    0 May 18 17:45 server-touch-home
drwx------ 2 worker worker 59 May 18 17:45 worker

### read from server ###
$ ls -l /nfs/home
total 0
-rw-r--r-- 1 root root  0 May 18 17:45 client-touch-home
-rw-r--r-- 1 root root  0 May 18 17:45 server-touch-home
drwx------ 2 1000 1000 59 May 18 17:45 worker
```

The directories of the `nfs` volume should now be populated (example using Linux volume mount).

```console
$ ls -lR nfs
nfs:
total 0
drwxrwxrwx 3 root root 67 May 18 13:45 home
drwxrwxrwx 2 root root 68 May 18 13:45 modulefiles
drwxrwxrwx 2 root root 60 May 18 13:45 modules
drwxrwxrwx 2 root root 58 May 18 13:45 secret

nfs/home:
total 0
-rw-r--r-- 1 root    root   0 May 18 13:45 client-touch-home
-rw-r--r-- 1 root    root   0 May 18 13:45 server-touch-home
drwx------ 2 1000    1000  59 May 18 13:45 worker
ls: cannot open directory nfs/home/worker: Permission denied

nfs/modulefiles:
total 0
-rw-r--r-- 1 root root 0 May 18 13:45 client-touch-modulefiles
-rw-r--r-- 1 root root 0 May 18 13:45 server-touch-modulefiles

nfs/modules:
total 0
-rw-r--r-- 1 root root 0 May 18 13:45 client-touch-modules
-rw-r--r-- 1 root root 0 May 18 13:45 server-touch-modules

nfs/secret:
total 0
-rw-r--r-- 1 root root 0 May 18 13:45 client-touch-secret
-rw-r--r-- 1 root root 0 May 18 13:45 server-touch-secret
```
