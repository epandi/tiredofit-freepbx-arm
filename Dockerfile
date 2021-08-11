###https://github.com/tiredofit/docker-debian/tree/buster
FROM debian:buster AS epandi-debian-buster
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

### Set defaults
ENV ZABBIX_VERSION=5.2 \
    S6_OVERLAY_VERSION=v2.1.0.2 \
    DEBUG_MODE=FALSE \
    TIMEZONE=Etc/GMT \
    DEBIAN_FRONTEND=noninteractive \
    ENABLE_CRON=TRUE \
    ENABLE_SMTP=TRUE \
    ENABLE_ZABBIX=TRUE \
    ZABBIX_HOSTNAME=debian.buster

### Dependencies addon
RUN set -x && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
            apt-transport-https \
            aptitude \
            bash \
            ca-certificates \
            curl \
            dirmngr \
            dos2unix \
            gnupg \
            less \
            logrotate \
            msmtp \
            nano \
            net-tools \
            netcat-openbsd \
            procps \
            sudo \
            tzdata \
            vim-tiny \
            wget \
            && \
### curl https://repo.zabbix.com/zabbix-official-repo.key | apt-key add - && \
### echo "deb http://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/debian buster main" >>/etc/apt/sources.list && \
### echo "deb-src http://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/debian buster main" >>/etc/apt/sources.list && \
    wget https://repo.zabbix.com/zabbix/5.2/raspbian/pool/main/z/zabbix-release/zabbix-release_5.2-1+debian$(cut -d"." -f1 /etc/debian_version)_all.deb && \
    dpkg -i zabbix-release_5.2-1+debian$(cut -d"." -f1 /etc/debian_version)_all.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
            zabbix-agent && \
    rm -rf /etc/zabbix/zabbix-agentd.conf.d/* && \
    curl -ksSLo /usr/local/bin/MailHog https://github.com/mailhog/MailHog/releases/download/v1.0.0/MailHog_linux_arm && \
    curl -ksSLo /usr/local/bin/mhsendmail https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_arm && \
    chmod +x /usr/local/bin/MailHog && \
    chmod +x /usr/local/bin/mhsendmail && \
    useradd -r -s /bin/false -d /nonexistent mailhog && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /root/.gnupg /var/log/* /etc/logrotate.d && \
    mkdir -p /assets/cron && \
    rm -rf /etc/timezone && \
    ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    echo '%zabbix ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    \
### S6 installation
    curl -ksSL https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-arm.tar.gz | tar xfz - --strip 0 -C /

### Networking configuration
EXPOSE 1025 8025 10050/TCP

### Add folders
ADD debian-buster/install /

### Entrypoint configuration
ENTRYPOINT ["/init"]



###https://github.com/tiredofit/docker-nodejs/tree/10/debian
FROM epandi-debian-buster AS epandi-nodejs-10-debian-latest
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

### Environment variables
ENV ENABLE_CRON=FALSE \
    ENABLE_SMTP=FALSE

### Add users
RUN adduser --home /app --gecos "Node User" --disabled-password nodejs && \
\
### Install NodeJS
    wget --no-check-certificate -qO - https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    echo 'deb https://deb.nodesource.com/node_10.x buster main' > /etc/apt/sources.list.d/nodesource.list && \
    echo 'deb-src https://deb.nodesource.com/node_10.x buster main' >> /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y \
            nodejs \
            yarn \
            && \
    \
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*



###https://github.com/tiredofit/docker-freepbx
FROM epandi-nodejs-10-debian-latest
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

### Set defaults
ENV ASTERISK_VERSION=17.9.3 \
    BCG729_VERSION=1.0.4 \
    DONGLE_VERSION=20200610 \
    G72X_CPUHOST=penryn \
    G72X_VERSION=0.1 \
    MONGODB_VERSION=4.2 \
    PHP_VERSION=5.6 \
    SPANDSP_VERSION=20180108 \
    RTP_START=18000 \
    RTP_FINISH=20000

### Pin libxml2 packages to Debian repositories
RUN c_rehash && \
    echo "Package: libxml2*" > /etc/apt/preferences.d/libxml2 && \
    echo "Pin: release o=Debian,n=buster" >> /etc/apt/preferences.d/libxml2 && \
    echo "Pin-Priority: 501" >> /etc/apt/preferences.d/libxml2 && \
    APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=TRUE && \
    \
### Install dependencies
    set -x && \
    curl https://packages.sury.org/php/apt.gpg | apt-key add - && \
    echo "deb https://packages.sury.org/php/ buster main" > /etc/apt/sources.list.d/deb.sury.org.list && \
#    curl https://www.mongodb.org/static/pgp/server-${MONGODB_VERSION}.asc | apt-key add - && \
#    echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/${MONGODB_VERSION} main" > /etc/apt/sources.list.d/mongodb-org.list && \
    echo "deb http://ftp.us.debian.org/debian/ buster-backports main" > /etc/apt/sources.list.d/backports.list && \
    echo "deb-src http://ftp.us.debian.org/debian/ buster-backports main" >> /etc/apt/sources.list.d/backports.list && \
    wget https://archive.raspbian.org/raspbian.public.key -O - | sudo apt-key add - && \
    echo "deb http://archive.raspbian.org/raspbian buster main contrib non-free" >>/etc/apt/sources.list && \
    echo "deb-src http://archive.raspbian.org/raspbian buster main contrib non-free" >>/etc/apt/sources.list && \
    apt-get update && \
    apt-get -o Dpkg::Options::="--force-confold" upgrade -y && \
    \
### Install development dependencies
    ASTERISK_BUILD_DEPS='\
                        autoconf \
                        automake \
                        bison \
                        binutils-dev \
                        build-essential \
                        doxygen \
                        flex \
                        graphviz \
                        libasound2-dev \
                        libbluetooth-dev \
                        libc-client2007e-dev \
                        libcfg-dev \
                        libcodec2-dev \
                        libcorosync-common-dev \
                        libcpg-dev \
                        libcurl4-openssl-dev \
                        libedit-dev \
                        libfftw3-dev \
                        libgmime-2.6-dev \
                        libgsm1-dev \
                        libical-dev \
                        libiksemel-dev \
                        libjansson-dev \
                        libldap2-dev \
                        liblua5.2-dev \
                        libmariadb-dev \
                        libmariadbclient-dev \
                        libmp3lame-dev \
                        libncurses5-dev \
                        libneon27-dev \
                        libnewt-dev \
                        libogg-dev \
                        libopus-dev \
                        libosptk-dev \
                        libpopt-dev \
                        libradcli-dev \
                        libresample1-dev \
                        libsndfile1-dev \
                        libsnmp-dev \
                        libspeex-dev \
                        libspeexdsp-dev \
                        libsqlite3-dev \
                        libsrtp2-dev \
                        libssl-dev \
                        libtiff-dev \
                        libtool-bin \
                        libunbound-dev \
                        liburiparser-dev \
                        libvorbis-dev \
                        libvpb-dev \
                        libxml2-dev \
                        libxslt1-dev \
                        linux-headers-armmp \
                        portaudio19-dev \
                        python-dev \
                        subversion \
                        unixodbc-dev \
                        uuid-dev \
                        zlib1g-dev' && \
    \
### Install runtime dependencies
    apt-get install --no-install-recommends -y \
                    $ASTERISK_BUILD_DEPS \
                    apache2 \
                    composer \
                    fail2ban \
                    ffmpeg \
                    flite \
                    freetds-dev \
                    git \
                    g++ \
                    iptables \
                    lame \
                    libavahi-client3 \
                    libbluetooth3 \
                    libc-client2007e \
                    libcfg7 \
                    libcpg4 \
                    libgmime-2.6 \
                    libical3 \
                    libiodbc2 \
                    libiksemel3 \
                    libicu63 \
                    libicu-dev \
                    libneon27 \
                    libosptk4 \
                    libresample1 \
                    libsnmp30 \
                    libspeexdsp1 \
                    libsrtp2-1 \
                    libunbound8 \
                    liburiparser1 \
                    libvpb1 \
                    locales \
                    locales-all \
                    make \
                    mariadb-client \
                    mariadb-server \
                    mongodb \
                    mpg123 \
                    php${PHP_VERSION} \
                    php${PHP_VERSION}-curl \
                    php${PHP_VERSION}-cli \
                    php${PHP_VERSION}-mysql \
                    php${PHP_VERSION}-gd \
                    php${PHP_VERSION}-mbstring \
                    php${PHP_VERSION}-intl \
                    php${PHP_VERSION}-bcmath \
                    php${PHP_VERSION}-ldap \
                    php${PHP_VERSION}-xml \
                    php${PHP_VERSION}-zip \
                    php${PHP_VERSION}-sqlite3 \
                    php-pear \
                    pkg-config \
                    sipsak \
                    sngrep \
                    socat \
                    sox \
                    sqlite3 \
                    tcpdump \
                    tcpflow \
                    unixodbc \
                    uuid \
                    wget \
                    whois \
                    xmlstarlet && \
    \
### Usbutils addon
    apt-get install usbutils unzip autoconf automake -y && \
    \  
### Add users
    addgroup --gid 2600 asterisk && \
    adduser --uid 2600 --gid 2600 --gecos "Asterisk User" --disabled-password asterisk && \
    \
### Build MardiaDB connector
    apt-get install -y cmake gcc && \
    cd /usr/src && \
    git clone https://github.com/MariaDB/mariadb-connector-odbc.git && \
    cd mariadb-connector-odbc && \
    git checkout tags/3.1.1-ga && \
    mkdir build && \
    cd build && \
    cmake ../ -LH -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DWITH_SSL=OPENSSL\
    -DDM_DIR=/usr/lib/arm-linux-gnueabihf -DCMAKE_C_FLAGS_RELEASE:STRING="-w" && \
    cmake --build . --config Release && \
    make install && \
    \
### Build SpanDSP
    mkdir -p /usr/src/spandsp && \
    curl -kL http://sources.buildroot.net/spandsp/spandsp-${SPANDSP_VERSION}.tar.gz | tar xvfz - --strip 1 -C /usr/src/spandsp && \
    cd /usr/src/spandsp && \
    ./configure --prefix=/usr && \
    make && \
    make install && \
    \
### Build Asterisk
    cd /usr/src && \
    mkdir -p asterisk && \
    curl -sSL http://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-${ASTERISK_VERSION}.tar.gz | tar xvfz - --strip 1 -C /usr/src/asterisk && \
    cd /usr/src/asterisk/ && \
    make distclean && \
    contrib/scripts/get_mp3_source.sh && \
    cd /usr/src/asterisk && \
    ./configure \
        --with-jansson-bundled \
        --with-pjproject-bundled \
        --with-bluetooth \
        --with-codec2 \
        --with-crypto \
        --with-gmime \
        --with-iconv \
        --with-iksemel \
        --with-inotify \
        --with-ldap \
        --with-libxml2 \
        --with-libxslt \
        --with-lua \
        --with-ogg \
        --with-opus \
        --with-resample \
        --with-spandsp \
        --with-speex \
        --with-sqlite3 \
        --with-srtp \
        --with-unixodbc \
        --with-uriparser \
        --with-vorbis \
        --with-vpb \
        && \
    \
    make menuselect/menuselect menuselect-tree menuselect.makeopts && \
    menuselect/menuselect --disable BUILD_NATIVE \
                          --enable-category MENUSELECT_ADDONS \
                          --enable-category MENUSELECT_APPS \
                          --enable-category MENUSELECT_CHANNELS \
                          --enable-category MENUSELECT_CODECS \
                          --enable-category MENUSELECT_FORMATS \
                          --enable-category MENUSELECT_FUNCS \
                          --enable-category MENUSELECT_RES \
                          --enable BETTER_BACKTRACES \
                          --disable MOH-OPSOUND-WAV \
                          --enable MOH-OPSOUND-GSM \
                          --disable app_voicemail_imap \
                          --disable app_voicemail_odbc \
                          --disable res_digium_phone \
                          --disable codec_g729a && \
    make && \
    make install && \
    make install-headers && \
    make config && \
    \
#### Add G729 codecs
    git clone https://github.com/BelledonneCommunications/bcg729 /usr/src/bcg729 && \
    cd /usr/src/bcg729 && \
    git checkout tags/$BCG729_VERSION && \
    ./autogen.sh && \
    ./configure --prefix=/usr --libdir=/lib && \
    make && \
    make install && \
    \
    mkdir -p /usr/src/asterisk-g72x && \
    curl https://bitbucket.org/arkadi/asterisk-g72x/get/master.tar.gz | tar xvfz - --strip 1 -C /usr/src/asterisk-g72x && \
    cd /usr/src/asterisk-g72x && \
    ./autogen.sh && \
    ./configure CFLAGS='-march=armv7' --prefix=/usr --with-bcg729 --enable-$G72X_CPUHOST && \
    make && \
    make install && \
    \
#### Add USB Dongle support
    git clone https://github.com/rusxakep/asterisk-chan-dongle /usr/src/asterisk-chan-dongle && \
    cd /usr/src/asterisk-chan-dongle && \
    git checkout tags/$DONGLE_VERSION && \
    ./bootstrap && \
    ./configure --with-astversion=$ASTERISK_VERSION && \
    make && \
    make install && \
    \
    ldconfig && \
    \
### Cleanup
    mkdir -p /var/run/fail2ban && \
    cd / && \
    rm -rf /usr/src/* /tmp/* /etc/cron* && \
    apt-get purge -y $ASTERISK_BUILD_DEPS && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    \
### FreePBX hacks
    sed -i -e "s/memory_limit = 128M/memory_limit = 256M/g" /etc/php/${PHP_VERSION}/apache2/php.ini && \
    sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php/${PHP_VERSION}/apache2/php.ini && \
    a2disconf other-vhosts-access-log.conf && \
    a2enmod rewrite && \
    a2enmod headers && \
    rm -rf /var/log/* && \
    mkdir -p /var/log/asterisk && \
    mkdir -p /var/log/apache2 && \
    mkdir -p /var/log/httpd && \
    \
### Zabbix setup
    echo '%zabbix ALL=(asterisk) NOPASSWD:/usr/sbin/asterisk' >> /etc/sudoers && \
    \
### Setup for data persistence
    mkdir -p /assets/config/var/lib/ /assets/config/home/ && \
    mv /home/asterisk /assets/config/home/ && \
    ln -s /data/home/asterisk /home/asterisk && \
    mv /var/lib/asterisk /assets/config/var/lib/ && \
    ln -s /data/var/lib/asterisk /var/lib/asterisk && \
    ln -s /data/usr/local/fop2 /usr/local/fop2 && \
    mkdir -p /assets/config/var/run/ && \
    mv /var/run/asterisk /assets/config/var/run/ && \
    mv /var/lib/mysql /assets/config/var/lib/ && \
    mkdir -p /assets/config/var/spool && \
    mv /var/spool/cron /assets/config/var/spool/ && \
    ln -s /data/var/spool/cron /var/spool/cron && \
    mkdir -p /var/run/mongodb && \
    rm -rf /var/lib/mongodb && \
    ln -s /data/var/lib/mongodb /var/lib/mongodb && \
    ln -s /data/var/run/asterisk /var/run/asterisk && \
    rm -rf /var/spool/asterisk && \
    ln -s /data/var/spool/asterisk /var/spool/asterisk && \
    rm -rf /etc/asterisk && \
    ln -s /data/etc/asterisk /etc/asterisk

### Networking configuration
EXPOSE 80 443 4445 4569 5060/udp 5160/udp 5061 5161 8001 8003 8008 8009 8025 ${RTP_START}-${RTP_FINISH}/udp

### Files add
ADD freepbx-15/install /