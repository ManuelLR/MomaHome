FROM homeassistant/home-assistant:2021.5.4

ENV \
    CUSTOM_COMPONENT_MITEMP_VERSION=1.9.2 \
    # syncthing => https://github.com/home-assistant/core/pull/38331
    CUSTOM_COMPONENT_SYNCTHING_VERSION=13b00d55914bb81c7be45af16b1328edd0ef9bb9 \
    CUSTOM_COMPONENT_GOOGLE_HOME=v1.4.3 \
    CUSTOM_COMPONENT_XIAOMI_CLOUD_MAP_EXTRACTOR=v1.1.1 \
    CUSTOM_CARD_XIAOMI_VACUUM_MAP=1.2.2 \
    CUSTOM_CARD_UPTIME=0.5.0 \
    CUSTOM_CARD_MINI_GRAPH=0.10.0 \
    CUSTOM_CARD_GOOGLE_HOME_TIMERS=0.2.0

RUN \
    set -ex \
    && apk add --no-cache --virtual build-dep \
      git \
    && mkdir -p /opt/HA/config/custom_components/ \
    # ble_monitor
    && git clone https://github.com/custom-components/ble_monitor.git /tmp/mitemp \
    && cd /tmp/mitemp && git checkout $CUSTOM_COMPONENT_MITEMP_VERSION \
    && cd - && cp -r /tmp/mitemp/custom_components/* /opt/HA/config/custom_components/ \
    # # syncthing
    # && git clone https://github.com/zhulik/core.git /tmp/syncthing \
    # && cd /tmp/syncthing && git checkout $CUSTOM_COMPONENT_SYNCTHING_VERSION \
    # && cd - && cp -r /tmp/syncthing/homeassistant/components/syncthing /opt/HA/config/custom_components/ \
    # ha-google-home
    && git clone https://github.com/leikoilja/ha-google-home.git /tmp/ha-google-home \
    && cd /tmp/ha-google-home && git checkout $CUSTOM_COMPONENT_GOOGLE_HOME \
    && cd - && cp -r /tmp/ha-google-home/custom_components/google_home /opt/HA/config/custom_components/ \
    # xiaomi-cloud-map-extractor
    && git clone https://github.com/PiotrMachowski/Home-Assistant-custom-components-Xiaomi-Cloud-Map-Extractor.git /tmp/xiaomi-cloud-map-extractor \
    && cd /tmp/xiaomi-cloud-map-extractor && git checkout $CUSTOM_COMPONENT_XIAOMI_CLOUD_MAP_EXTRACTOR \
    && cd - && cp -r /tmp/xiaomi-cloud-map-extractor/custom_components/xiaomi_cloud_map_extractor /opt/HA/config/custom_components/ \
    ## ----------  Cards  ----------
    && mkdir -p /HA-custom-www/external-cards/ \
    # Xiaomi vacuum map card
    && git clone https://github.com/PiotrMachowski/lovelace-xiaomi-vacuum-map-card.git /tmp/xiaomi-vacuum-map-card \
      && cd /tmp/xiaomi-vacuum-map-card && git checkout v$CUSTOM_CARD_XIAOMI_VACUUM_MAP \
      && mkdir -p /HA-custom-www/external-cards/xiaomi-vacuum-map-card \
      && cd - && cp -r /tmp/xiaomi-vacuum-map-card/dist/* /HA-custom-www/external-cards/xiaomi-vacuum-map-card/ \
    # Uptime Card
    && curl -fsSL "https://github.com/dylandoamaral/uptime-card/releases/download/v${CUSTOM_CARD_UPTIME}/uptime-card.js" -o /HA-custom-www/external-cards/uptime-card.js \
    # Mini Graph Card
    && curl -fsSL "https://github.com/kalkih/mini-graph-card/releases/download/v${CUSTOM_CARD_MINI_GRAPH}/mini-graph-card-bundle.js" -o /HA-custom-www/external-cards/mini-graph-card-bundle.js \
    # Google Home Card
    && git clone https://github.com/DurgNomis-drol/google_home_timers_card.git /tmp/google_home_timers_card \
    && cd /tmp/google_home_timers_card && git checkout v$CUSTOM_CARD_GOOGLE_HOME_TIMERS \
    && cd - && cp -r /tmp/google_home_timers_card/googletimers-card.js /HA-custom-www/external-cards/ \
    && apk del build-dep

COPY prepare.sh /etc/cont-init.d/
