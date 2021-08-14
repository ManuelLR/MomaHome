FROM homeassistant/home-assistant:2021.8.6

##### Pending tasks
# - Add remote controller for TV in the UI
# - Add id to triggers to easily filter in the future

ENV \
    CUSTOM_COMPONENT_BLE_MONITOR_VERSION=4.5.1 \
    CUSTOM_COMPONENT_GOOGLE_HOME=v1.6.1 \
    CUSTOM_COMPONENT_XIAOMI_CLOUD_MAP_EXTRACTOR=v2.1.1 \
    CUSTOM_COMPONENT_DYSON_LOCAL=0.15.0 \
    CUSTOM_CARD_XIAOMI_VACUUM_MAP=1.2.3 \
    CUSTOM_CARD_UPTIME=0.6.0 \
    CUSTOM_CARD_MINI_GRAPH=0.10.0 \
    CUSTOM_CARD_TV_REMOTE=0.1.4 \
    CUSTOM_CARD_GOOGLE_HOME_TIMERS=0.2.0

RUN \
    set -ex \
    && apk add --no-cache --virtual build-dep \
      git \
    && mkdir -p /opt/HA/config/custom_components/ \
    # ble_monitor
    && git clone https://github.com/custom-components/ble_monitor.git /tmp/ble_monitor \
    && cd /tmp/ble_monitor && git checkout $CUSTOM_COMPONENT_BLE_MONITOR_VERSION \
    && cd - && cp -r /tmp/ble_monitor/custom_components/* /opt/HA/config/custom_components/ \
    # ha-google-home
    && git clone https://github.com/leikoilja/ha-google-home.git /tmp/ha-google-home \
    && cd /tmp/ha-google-home && git checkout $CUSTOM_COMPONENT_GOOGLE_HOME \
    && cd - && cp -r /tmp/ha-google-home/custom_components/google_home /opt/HA/config/custom_components/ \
    # xiaomi-cloud-map-extractor
    && git clone https://github.com/PiotrMachowski/Home-Assistant-custom-components-Xiaomi-Cloud-Map-Extractor.git /tmp/xiaomi-cloud-map-extractor \
    && cd /tmp/xiaomi-cloud-map-extractor && git checkout $CUSTOM_COMPONENT_XIAOMI_CLOUD_MAP_EXTRACTOR \
    && cd - && cp -r /tmp/xiaomi-cloud-map-extractor/custom_components/xiaomi_cloud_map_extractor /opt/HA/config/custom_components/ \
    # dyson-local
    && git clone https://github.com/shenxn/ha-dyson.git /tmp/ha-dyson-local \
    && cd /tmp/ha-dyson-local && git checkout $CUSTOM_CUSTOM_COMPONENT_DYSON_LOCAL \
    && cd - && cp -r /tmp/ha-dyson-local/custom_components/dyson_local /opt/HA/config/custom_components/ \
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
    # TV remote Card
    && git clone https://github.com/marrobHD/tv-card.git /tmp/tv_remote_card \
    && cd /tmp/tv_remote_card && git checkout v$CUSTOM_CARD_TV_REMOTE \
    && cd - && cp -r /tmp/tv_remote_card/tv-card*.js /HA-custom-www/external-cards/ \
    # Google Home Card
    && git clone https://github.com/DurgNomis-drol/google_home_timers_card.git /tmp/google_home_timers_card \
    && cd /tmp/google_home_timers_card && git checkout v$CUSTOM_CARD_GOOGLE_HOME_TIMERS \
    && cd - && cp -r /tmp/google_home_timers_card/googletimers-card.js /HA-custom-www/external-cards/ \
    && apk del build-dep

COPY prepare.sh /etc/cont-init.d/
