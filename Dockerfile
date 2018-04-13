FROM alpine:3.7

##### VERSIONS #####
ARG MAJOR
ARG MINOR
ARG PATCH

ARG CDB_VERSION="0.78"
##### VERSIONS #####

##### CONFIGURATIONS #####
ARG MAKEOPTS="-j1"
ARG CFLAGS="-O2"
##### CONFIGURATIONS #####

LABEL maintainer="g0dsCookie <g0dscookie@cookieprojects.de>" \
      version="${MAJOR}.${MINOR}.${PATCH}" \
      description="A fast and secure drop-in replacement for sendmail"

COPY patches/* /tmp/patches/

RUN set -eu \
    && apk add --no-cache --virtual .postfix-deps \
        pcre \
        perl \
        db \
        icu \
        openldap \
        lmdb \
        mariadb-client-libs \
        libnsl \
        postgresql \
        cyrus-sasl \
        sqlite-libs \
        libressl \
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
        perl-dev \
        db-dev \
        icu-dev \
        openldap-dev \
        lmdb-dev \
        mariadb-dev \
        libnsl-dev \
        postgresql-dev \
        cyrus-sasl-dev \
        sqlite-dev \
        libressl-dev \
        bsd-compat-headers \
    && addgroup -S postfix && adduser -h /var/spool/postfix -H -s /sbin/nologin -S -g postfix postfix \
    && addgroup -S postdrop \
    && BDIR="$(mktemp -d)" \
    && cd "${BDIR}" \
    && wget -qO - "http://www.corpit.ru/mjt/tinycdb/tinycdb-${CDB_VERSION}.tar.gz" |\
        tar -xzf - \
    && wget -qO - "http://cdn.postfix.johnriley.me/mirrors/postfix-release/official/postfix-${MAJOR}.${MINOR}.${PATCH}.tar.gz" |\
        tar -xzf - \
    && cd "tinycdb-${CDB_VERSION}" \
    && make ${MAKEOPTS} CFLAGS="${CFLAGS}" shared \
    && make prefix=/usr install install-sharedlib \
    && cd "../postfix-${MAJOR}.${MINOR}.${PATCH}" \
    && patch -p1 -i /tmp/patches/libressl.patch \
    && make makefiles shared=yes dynamicmaps=no shlib_directory="/usr/lib/postfix/MAIL_VERSION" \
        DEBUG="" OPT="${CFLAGS}" \
        CCARGS="-DHAS_PCRE -DHAS_LDAP -DHAS_MYSQL -I/usr/include/mysql -DHAS_PGSQL -I/usr/include/postgresql -DHAS_SQLITE -DUSE_TLS -DHAS_LMDB -DDEF_SASL_SERVER=\"dovecot\" -DUSE_LDAP_SASL -DUSE_SASL_AUTH -DUSE_CYRUS_SASL -I/usr/include/sasl -DHAS_CDB -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE" \
        AUXLIBS="-ldl -lpcre -llmdb -lssl -lcrypto -lsasl2" AUXLIBS_CDB="-lcdb" \
        AUXLIBS_LDAP="-lldap -llber" AUXLIBS_MYSQL="-lmysqlclient" \
        AUXLIBS_PGSQL="-L/usr/lib/postgresql -lpq" AUXLIBS_SQLITE="-lsqlite3 -lpthread" \
        AUXLIBS_LMDB="-llmdb -lpthread" \
    && make ${MAKEOPTS} \
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
    && mkdir /queue

EXPOSE 25 587

VOLUME [ "/queue", "/etc/postfix" ]

ENTRYPOINT [ "/usr/sbin/postfix", "start-fg" ]