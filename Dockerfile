#
# TorrServer with qBittorrent
#

FROM alpine:latest
ARG BUILD_DATE
ARG VERSION
ARG QBITTORRENT_VERSION
ARG QBT_VERSION
ARG UNRAR_VERSION=6.2.8
ENV HOME="/config" \
XDG_CONFIG_HOME="/config" \
XDG_DATA_HOME="/config"
ENV TS_GIT_URL="https://api.github.com/repos/YouROK/TorrServer/releases"
ENV TS_HOME_URL="https://releases.yourok.ru/torr/server_release.json"
ENV TS_RELEASE="latest"
ENV TS_PORT=8090
ENV TS_CONF_PATH=/TS/db
ENV TS_CACHE_PATH=/TS/db/cache
ENV TS_LOG=/TS/db/ts.log
ENV TS_STAT=/TS/db/ts_stat.json

ENV QBT_TORR_DIR=/TS/db/torrents
ENV QBT_TRACKERS_URL="https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best_ip.txt"

ENV FILES_URL="https://raw.githubusercontent.com/MrKsey/torrserver-plus/main"
ENV FFBINARIES="https://ffbinaries.com/api/v1/version/latest"
ENV USER_AGENT="Mozilla/5.0 (X11; Linux x86_64; rv:77.0) Gecko/20100101 Firefox/77.0"


# On linux systems you need to set this environment variable before run:
ENV GODEBUG="madvdontneed=1"

COPY start.sh /start.sh
COPY config.sh /config.sh
COPY update.sh /update.sh
COPY ts_log_listener.sh /ts_log_listener.sh
COPY qbt_manager.sh /qbt_manager.sh
COPY qbt_resume_torrents.sh /qbt_resume_torrents.sh
COPY ps_exit.sh /ps_exit.sh


RUN echo "**** install build packages ****" && \
   apk add --no-cache --virtual=build-dependencies \
   build-base && \
   echo "**** install packages ****" && \
   apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    icu-libs \
    libstdc++ \
    openssl \
    openssl1.1-compat \
    p7zip \
    python3 \
    qt6-qtbase-sqlite \
    ca-certificates \
    tzdata \
    wget \
    curl \
    procps \
    file \
    jq \
    unzip \
    tzdata wget curl procps file jq unzip gnupg binutils moreutils speedtest-cli dos2unix iproute2 \
    musl-locales \
   && strip --remove-section=.note.ABI-tag $(find /usr/. -name "libQt6Core.so.6") \
   && dos2unix /start.sh && dos2unix /config.sh && dos2unix /update.sh && dos2unix /ts_log_listener.sh && dos2unix /qbt_manager.sh && dos2unix /qbt_resume_torrents.sh && dos2unix /ps_exit.sh \
&& chmod +x /start.sh && chmod +x /config.sh && chmod +x /update.sh && chmod +x /ts_log_listener.sh && chmod +x /qbt_manager.sh && chmod +x /qbt_resume_torrents.sh && chmod +x /ps_exit.sh \
&& mkdir -p /TS && chmod -R 666 /TS \
&& mkdir -p $TS_CONF_PATH && chmod -R 666 $TS_CONF_PATH \
&& export TS_URL=$TS_GIT_URL/$([ "$TS_RELEASE" != "latest" ] && echo tags/$TS_RELEASE || echo $TS_RELEASE) \
&& wget --no-verbose --no-check-certificate --user-agent="$USER_AGENT" --output-document=/TS/TorrServer --tries=3 $(\
   curl -s $TS_URL | grep -o -E 'http.+\w+' | grep -i "$(uname)" | grep -i "$(dpkg --print-architecture | sed "s/armhf/arm7/g")") \
&& chmod a+x /TS/TorrServer \
&& wget --no-verbose --no-check-certificate --user-agent="$USER_AGENT" --output-document=/tmp/ffprobe.zip --tries=3 $(\
   curl -s $FFBINARIES | jq '.bin | .[].ffprobe' | grep linux | \
   grep -i -E "$(dpkg --print-architecture | sed "s/amd64/linux-64/g" | sed "s/arm64/linux-arm-64/g" | sed -E "s/armhf/linux-armhf-32/g")" | jq -r) \
&& unzip -x -o /tmp/ffprobe.zip ffprobe -d /usr/local/bin \
&& chmod -R +x /usr/local/bin \
&& touch /var/log/cron.log \
&& ln -sf /proc/1/fd/1 /var/log/cron.log \
&& locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

HEALTHCHECK --interval=5s --timeout=10s --retries=3 CMD curl -sS 127.0.0.1:$TS_PORT || exit 1
COPY root/ /
VOLUME [ "$TS_CONF_PATH" ]
VOLUME /config
EXPOSE 8080 6881 6881/udp
CMD ["/start.sh"]
