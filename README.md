# dovecot image

This image provides an *unofficial* dockerized postfix image.

## Table of Contents

1. [Supported tags and versions](#supported-tags-and-versions)
2. [Quick reference](#quick-reference)
3. [How to use this image](#how-to-use-this-image)
    1. [Run the container](#run-the-container)
    2. [Use custom container](#use-custom-container)
    3. [Use bind mounts](#use-bind-mounts)
    4. [Available volumes](#available-volumes)

## Supported tags and versions

* [`3.3.0`, `3.3`, `3`, `latest` (*3.3/Dockerfile*)](https://github.com/g0dsCookie/docker-postfix/blob/master/Dockerfile)

## Quick reference

* **Where to file issues**:

    [https://github.com/g0dsCookie/docker-postfix/issues](https://github.com/g0dsCookie/docker-postfix/issues)

* **Maintained by**:

    [g0dsCookie](https://github.com/g0dsCookie)

## How to use this image

### Run the container

This container uses postfix default configuration.

Please note that you should not override the following files.
If you want to mount a directory to **/etc/postfix** remember to copy those first.
Paths ending with a */* are directories.

* dynamicmaps.cf
* dynamicmaps.cf.d/
* main.cf.default
* main.cf.proto
* makedefs.out
* master.cf.proto
* postfix-files
* postfix-files.d/

If you don't copy/keep these files, you will break things.

### Use custom container

```Dockerfile
FROM g0dscookie/postfix
COPY config/ /etc/postfix/
```

Now build your container with `$ docker build -t my-postfix .`.

Note: Do not override the files mentioned above.

### Use bind mounts

`$ docker run -d --name my-postfix -v /path/to/config:/conf:ro -v /my/certificates:/certificates:ro -v /path/to/queue:/queue g0dscookie/postfix`

Note that **/path/to/config** is a directory.

Second note: Do not override the files mentioned above.

### Available volumes

* /queue
  * Here you can persistently store your postfix queue.
* /certificates
  * Here you can mount your certificates used by postfix.
* /conf
  * Postfix configuration files.

## Update instructions

1. Add new postfix version to `build.py`
2. `make VERSION="<VERSION>"`
    1. Omit `VERSION=` or set `<VERSION>` to **latest** if you are building a latest version.
3. `make push`
4. Commit your changes and push them
