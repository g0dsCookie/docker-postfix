FROM alpine:edge

COPY patches/* /tmp/patches/

RUN apk add --no-cache --virtual .postfix-deps \
        pcre libpcrecpp libpcre16 libpcre32 \
        db \
        icu \
        openldap \
        lmdb \
        mariadb-connector-c \
        libnsl \
        postgresql-libs \
        cyrus-sasl \
        sqlite-libs \
        libressl \
        zlib \
 && addgroup -S postfix && adduser -h /var/spool/postfix -H -s /sbin/nologin -S -g postfix postfix \
 && addgroup -S postdrop

##### CONFIGURATIONS #####
ARG MAKEOPTS="-j1"
ARG CFLAGS="-O2"
##### CONFIGURATIONS #####

##### CDB VERSION #####
ARG CDB_VERSION="0.78"
##### CDB VERSION #####

RUN set -eu \
 && apk add --no-cache --virtual .build-deps \
        gcc g++ \
        libc-dev rpcgen \
        make \
        tar \
        gzip \
        wget \
        linux-headers \
 && BDIR="$(mktemp -d)" \
 && cd "${BDIR}" \
 && wget -qO - "http://www.corpit.ru/mjt/tinycdb/tinycdb-${CDB_VERSION}.tar.gz" |\
        tar -xzf - \
 && cd "tinycdb-${CDB_VERSION}" \
 && make ${MAKEOPTS} CFLAGS="${CFLAGS}" shared \
 && make prefix=/usr install install-sharedlib \
 && cd \
 && rm -r "${BDIR}" \
 && apk del .build-deps

##### VERSIONS #####
ARG MAJOR
ARG MINOR
ARG PATCH
##### VERSIONS #####

LABEL maintainer="g0dsCookie <g0dscookie@cookieprojects.de>" \
      version="${MAJOR}.${MINOR}.${PATCH}" \
      description="A fast and secure drop-in replacement for sendmail"

RUN set -eu \
    && apk add --no-cache --virtual .build-deps \
        gcc g++ \
        libc-dev rpcgen \
        make \
        patch \
        tar \
        gzip \
        wget \
        file \
        coreutils \
        linux-headers \
        pcre-dev \
        perl \
        db-dev \
        icu-dev \
        openldap-dev \
        lmdb-dev \
        mariadb-connector-c-dev \
        libnsl-dev \
        postgresql-dev \
        cyrus-sasl-dev \
        sqlite-dev \
        libressl-dev \
        zlib-dev \
        bsd-compat-headers \
    && BDIR="$(mktemp -d)" \
    && cd "${BDIR}" \
    && wget -qO - "http://cdn.postfix.johnriley.me/mirrors/postfix-release/official/postfix-${MAJOR}.${MINOR}.${PATCH}.tar.gz" |\
        tar -xzf - \
    && cd "postfix-${MAJOR}.${MINOR}.${PATCH}" \
    && for p in /tmp/patches/*.patch; do patch -p1 -i "${p}"; done \
    && make makefiles shared=yes dynamicmaps=yes \
        DEBUG="" OPT="${CFLAGS}" \
        CCARGS="-DHAS_SHL_LOAD -DDEF_DAEMON_DIR=\\\"/usr/lib/postfix\\\" -DHAS_PCRE $(pcre-config --cflags) -DHAS_LDAP -DHAS_MYSQL $(mysql_config --cflags) -DHAS_PGSQL -I/usr/include/postgresql -DHAS_SQLITE -DUSE_TLS -DHAS_LMDB -DDEF_SASL_SERVER=\\\"dovecot\\\" -DUSE_LDAP_SASL -DUSE_SASL_AUTH -DUSE_CYRUS_SASL -I/usr/include/sasl -DHAS_CDB -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE" \
        AUXLIBS="-ldl $(pcre-config --libs) -llmdb -lssl -lcrypto -lsasl2" AUXLIBS_CDB="-lcdb" \
        AUXLIBS_LDAP="-lldap -llber" AUXLIBS_MYSQL="$(mysql_config --libs)" \
        AUXLIBS_PGSQL="-L/usr/lib/postgresql -lpq" AUXLIBS_SQLITE="-lsqlite3 -lpthread" \
        AUXLIBS_LMDB="-llmdb -lpthread" \
    && make ${MAKEOPTS} \
    && mkdir /conf \
    && ln -s /conf /etc/postfix \
    && LD_LIBRARY_PATH="lib" sh postfix-install \
        -non-interactive \
        install_root="/" \
        config_directory="/etc/postfix" \
        manpage_directory="/usr/share/man" \
        command_directory="/usr/sbin" \
        mailq_path="/usr/bin/mailq" \
        newaliases_path="/usr/bin/newaliases" \
        sendmail_path="/usr/sbin/sendmail" \
    && cd && rm -r "${BDIR}" "/tmp/patches" \
    && apk del .build-deps \
    && mkdir /queue /certificates

EXPOSE 25 587

VOLUME [ "/queue", "/conf", "/certificates" ]

ENTRYPOINT [ "/usr/sbin/postfix", "start-fg", "-c", "/conf" ]