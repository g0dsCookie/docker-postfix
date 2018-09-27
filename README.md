# postfix image

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

* [`3.3.1`, `3.3`, `3`, `latest` (*3.3/Dockerfile*)](https://github.com/g0dsCookie/docker-postfix/blob/master/Dockerfile)

## Quick reference

* **Where to file issues**:

    [https://github.com/g0dsCookie/docker-postfix/issues](https://github.com/g0dsCookie/docker-postfix/issues)

* **Maintained by**:

    [g0dsCookie](https://github.com/g0dsCookie)

## How to use this image

### Run the container

This container uses postfix default configuration. You can mount your configuration on **/etc/postfix**. Please note that the following files are default installation specific files and **should not** be mounted into the container.

* dynamicmaps.cf
* dynamicmaps.cf.d/
* main.cf.proto
* makedefs.out
* master.cf.proto
* postfix-files
* postfix-files.d/

`docker run -itd --name postfix -v /postfix/conf:/etc/postfix g0dscookie/postfix`

### Postfix Logs

Postfix only supports logging to a local syslog daemon on /dev/log. To get your logs you have to bind mount this socket:

`docker run -itd --name postfix -v /dev/log:/dev/log g0dscookie/postfix`

### Use custom container

```Dockerfile
FROM g0dscookie/postfix
COPY config/ /etc/postfix/
```

Now build your container with `$ docker build -t my-postfix .`.

### Available volumes

- /queue
    - Here you can persistently store your postfix queue. You can still use the default /var/spool/postfix if you prefer.
- /certificates
    - Here you can mount your certificates for postfix.
- /etc/postfix
    - Postfix will load it's configuration from here.

### Use bind mounts

`$ docker run -d --name my-postfix -v /path/to/config:/conf -v /my/certificates:/certificates:ro -v /path/to/queue:/queue g0dscookie/postfix`

Note that **/path/to/config** is a directory.

Second note: Do not override the files mentioned above.

### Available volumes

* /queue
  * Here you can persistently store your postfix queue.
* /certificates
  * Here you can mount your certificates used by postfix.
* /conf
  * Postfix configuration files.
