FROM debian:10

ARG MAJOR
ARG MINOR
ARG PATCH

LABEL maintainer="g0dsCookie <g0dscookie@cookieprojects.de>" \
      description="A fast and secure drop-in replacement for sendmail" \
      version="${MAJOR}.${MINOR}.${PATCH}"

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eu \
 && cecho() { echo "\033[1;32m$1\033[0m"; } \
 && cecho "### PREPARE ENVIRONMENT ###" \
 && TMP="$(mktemp -d)" && PV="${MAJOR}.${MINOR}.${PATCH}" && S="${TMP}/postfix-${PV}" \
 && useradd -d /var/spool/postfix -M -s /sbin/nologin -r postfix \
 && groupadd -r postdrop \
 && mkdir /var/spool/postfix \
 && mkdir /queue && chown postfix:postfix /queue && chmod 0700 /queue \
 && cecho "### INSTALLING DEPENDENCIES ###" \
 && apt-get update -qq \
 && apt-get install -qqy \
     build-essential curl gnupg pkg-config \
     libmagic-dev libpcre3-dev perl libdb-dev \
     libicu-dev libldap2-dev liblmdb-dev libmariadbclient-dev libmariadb-dev-compat \
     libpq-dev libsasl2-dev libsqlite3-dev \
     libssl-dev zlib1g-dev libcdb-dev m4 \
 && apt-get install -qqy \
     libmagic1 libpcre3 libdb5.3 \
     libicu63 libldap-2.4-2 liblmdb0 libmariadb3 \
     libpq5 libsasl2-2 libsqlite3-0 \
     openssl zlib1g tinycdb \
 && cecho "### DOWNLOADING POSTFIX ###" \
 && cd "${TMP}" \
 && curl -sSL -o "postfix-${PV}.tar.gz" "http://cdn.postfix.johnriley.me/mirrors/postfix-release/official/postfix-${PV}.tar.gz" \
 && tar -xf "postfix-${PV}.tar.gz" \
 && cd "postfix-${PV}" \
 && make makefiles shared=yes dynamicmaps=no \
      shlib_directory="/usr/lib/postfix/MAIL_VERSION" \
      meta_directory="/usr/share/postfix" \
      DEBUG="" OPT="-O2" \
      CCARGS="-DHAS_SHL_LOAD -DDEF_DAEMON_DIR=\\\"/usr/libexec/postfix\\\" -DHAS_PCRE $(pcre-config --cflags) -DHAS_LDAP -DHAS_MYSQL $(mysql_config --cflags) -DHAS_PGSQL -I/usr/include/postgresql -DHAS_SQLITE -DUSE_TLS -DHAS_LMDB -DDEF_SASL_SERVER=\\\"dovecot\\\" -DUSE_LDAP_SASL -DUSE_SASL_AUTH -DUSE_CYRUS_SASL -I/usr/include/sasl -DHAS_CDB -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE" \
      AUXLIBS="-ldl $(pcre-config --libs) -llmdb -lssl -lcrypto -lsasl2" AUXLIBS_CDB="-lcdb" \
      AUXLIBS_LDAP="-lldap -llber" AUXLIBS_MYSQL="$(mysql_config --libs)" \
      AUXLIBS_PGSQL="-L/usr/lib/postgresql -lpq" AUXLIBS_SQLITE="-lsqlite3 -lpthread" \
      AUXLIBS_LMDB="-llmdb -lpthread" \
 && make -j$(nproc) \
 && LD_LIBRARY_PATH="lib" sh postfix-install \
      -non-interactive \
      install_root="/" \
      config_directory="/etc/postfix" \
      manpage_directory="/usr/share/man" \
      command_directory="/usr/sbin" \
      mailq_path="/usr/bin/mailq" \
      newaliases_path="/usr/bin/newaliases" \
      sendmail_path="/usr/sbin/sendmail" \
 && postconf maillog_file=/dev/stdout \
 && postconf queue_directory=/queue \
 && cecho "### CLEANUP ###" \
 && cd && rm -rf "${TMP}" \
 && apt-get remove -qqy \
      build-essential curl gnupg pkg-config \
      libmagic-dev libpcre3-dev perl libdb-dev \
      libicu-dev libldap2-dev liblmdb-dev libmariadbclient-dev libmariadb-dev-compat \
      libpq-dev cyrus-dev libsqlite3-dev \
      libssl-dev zlib1g-dev libcdb-dev m4 \
 && apt-get autoremove -qqy \
 && apt-get clean -qqy

EXPOSE 25 465 587
VOLUME [ "/queue", "/etc/postfix" ]
ENTRYPOINT [ "/usr/sbin/postfix", "start-fg" ]
