FROM alpine:3.11

LABEL maintainer="g0dsCookie <g0dscookie@cookieprojects.de>" \
      description="A fast and secure drop-in replacement for sendmail"

ARG CDB_VERSION="0.78"

LABEL cdb_version="${CDB_VERSION}"

RUN set -eu \
 && cecho() { echo "\033[1;32m$1\033[0m"; } \
 && cecho "##### INSTALLING CDB #####" \
 && apk add --no-cache --virtual .cdb-bdeps \
       gcc g++ libc-dev rpcgen make tar gzip curl linux-headers \
 && MAKEOPTS="-j$(nproc)" \
 && BDIR="$(mktemp -d)" && cd "${BDIR}" \
 && curl -sSL -o "tinycdb-${CDB_VERSION}.tar.gz" "http://www.corpit.ru/mjt/tinycdb/tinycdb-${CDB_VERSION}.tar.gz" \
 && tar -xzf "tinycdb-${CDB_VERSION}.tar.gz" \
 && cd "tinycdb-${CDB_VERSION}" \
 && make ${MAKEOPTS} shared && make prefix=/usr install install-sharedlib \
 && make ${MAKEOPTS} CFLAGS="-O2" shared \
 && make prefix=/usr install install-sharedlib \
 && cecho "##### REMOVING BUILD DEPS #####" \
 && cd && rm -r "${BDIR}" && apk del .cdb-bdeps

ARG MAJOR
ARG MINOR
ARG PATCH

LABEL version="${MAJOR}.${MINOR}.${PATCH}"

RUN set -eu \
 && cecho() { echo "\033[1;32m$1\033[0m"; } \
 && cecho "##### CREATING POSTFIX USER #####" \
 && addgroup -S postfix && adduser -h /var/spool/postfix -H -s /sbin/nologin -S -g postfix postfix \
 && addgroup -S postdrop \
 && mkdir /queue /certificates \
 && cecho "##### INSTALLING POSTFIX #####" \
 && apk add --no-cache --virtual .postfix-deps \
       pcre libpcrecpp libpcre16 libpcre32 \
       db icu openldap lmdb mariadb-connector-c \
       libnsl postgresql-libs cyrus-sasl \
       sqlite-libs openssl zlib \
 && apk add --no-cache --virtual .postfix-bdeps \
       gcc g++ m4 libc-dev rpcgen make tar gzip curl \
       file coreutils linux-headers pcre-dev perl db-dev \
       icu-dev openldap-dev lmdb-dev mariadb-connector-c-dev \
       libnsl-dev postgresql-dev cyrus-sasl-dev sqlite-dev \
       openssl-dev zlib-dev bsd-compat-headers \
 && MAKEOPTS="-j$(nproc)" \
 && BDIR="$(mktemp -d)" && cd "${BDIR}" \
 && curl -sSL -o "postfix-${MAJOR}.${MINOR}.${PATCH}.tar.gz" "http://cdn.postfix.johnriley.me/mirrors/postfix-release/official/postfix-${MAJOR}.${MINOR}.${PATCH}.tar.gz" \
 && tar -xzf "postfix-${MAJOR}.${MINOR}.${PATCH}.tar.gz" \
 && cd "postfix-${MAJOR}.${MINOR}.${PATCH}" \
 && make makefiles shared=yes dynamicmaps=no \
       shlib_directory="/usr/lib/postfix/MAIL_VERSION" \
       meta_directory="/usr/share/postfix" \
       DEBUG="" OPT="-O2" \
       CCARGS="-DHAS_SHL_LOAD -DDEF_DAEMON_DIR=\\\"/usr/libexec/postfix\\\" -DHAS_PCRE $(pcre-config --cflags) -DHAS_LDAP -DHAS_MYSQL $(mysql_config --cflags) -DHAS_PGSQL -I/usr/include/postgresql -DHAS_SQLITE -DUSE_TLS -DHAS_LMDB -DDEF_SASL_SERVER=\\\"dovecot\\\" -DUSE_LDAP_SASL -DUSE_SASL_AUTH -DUSE_CYRUS_SASL -I/usr/include/sasl -DHAS_CDB -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE" \
       AUXLIBS="-ldl $(pcre-config --libs) -llmdb -lssl -lcrypto -lsasl2" AUXLIBS_CDB="-lcdb" \
       AUXLIBS_LDAP="-lldap -llber" AUXLIBS_MYSQL="$(mysql_config --libs)" \
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
 && cecho "##### CLEANING BUILD ENVIRONMENT #####" \
 && cd && rm -r "${BDIR}" && apk del .postfix-bdeps

EXPOSE 25 465 587

VOLUME [ "/queue", "/etc/postfix", "/certificates" ]

ENTRYPOINT [ "/usr/sbin/postfix", "start-fg" ]
