# Atticache

Atticache is a [fly.io](fly.io)-based instance of [attic-server](https://github.com/zhaofengli/attic), currently hosted at [cache.usertam.dev](https://cache.usertam.dev) and [atticache.fly.dev](https://atticache.fly.dev).

This repository contains the configurations for the [attic-server](https://github.com/zhaofengli/attic) image and for the [fly.io](fly.io) deployment.

We configure `min_machines_running = 0` so the machines will stop when there is no open connections, and `auto_stop_machines = 'suspend'` so the machines will be suspended instead of stopped.

## Deploy to fly.io

### Build docker image (x86_64-linux)
This will place a symlink `./result` pointing to the built docker image.
```
nix build -L .#packages.x86_64-linux.attic-server-image
```
```
$ ls -la result                             
lrwxr-xr-x result -> /nix/store/<hash>-docker-image-attic-server.tar.gz
```

### Copy image to registry.fly.io
We can directly use `skopeo` to copy the image to the registry, without needing `docker`.
```
nix shell nixpkgs#skopeo
skopeo --insecure-policy --override-arch amd64 --override-os linux \
    copy docker-archive://$PWD/result docker://registry.fly.io/atticache:latest
```

### Set secrets
The environment variables at `server.toml` are placeholders. Set the actual values using `fly secrets`.
```sh
nix shell nixpkgs#flyctl
# Replace with actual values.
fly secrets set ATTIC_SERVER_DATABASE_URL='postgres://...'
fly secrets set ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=''
fly secrets set AWS_ACCESS_KEY_ID=''
fly secrets set AWS_SECRET_ACCESS_KEY=''
```

### Deploy
```
fly deploy
```

## Fly ssh console usage
We have only a relatively minimal bash shell inside the container, with no `coreutils`. For example, you can use `echo /bin/*` and `echo "$(</etc/passwd)"` instead of `ls /bin` and `cat /etc/passwd`.
```sh
$ fly ssh console
Connecting to ffff:f:ffff:fff:ffff:ffff:ffff:f... complete
-sh-5.2# echo "$(</etc/passwd)"
root:x:0:0:root user:/var/empty:/bin/sh
nobody:x:65534:65534:nobody:/var/empty:/bin/sh
-sh-5.2# echo /bin/attic* /nix/store/*-server.toml
/bin/atticadm /bin/atticd /nix/store/<hash>-server.toml
```

### Make JWT token with `atticadm`
```sh
-sh-5.2# /bin/atticadm -f /nix/store/*-server.toml make-token \
> --sub "<subject>" --validity "10y" --pull "*" --push "*"
<jwt_token>
```
