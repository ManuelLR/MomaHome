FROM homeassistant/home-assistant:2022.4.7

##### Pending tasks
# - Add backup and auto-exec it: https://www.home-assistant.io/integrations/backup/
# - Add id to triggers to easily filter in the future
# - Input_button could be really helpful
# - Add the update option to espurna/tasmota/esphome: https://www.home-assistant.io/blog/2022/04/06/release-20224/#introducing-update-entities

ENV \
    ## DOCU: https://docs.renovatebot.com/modules/manager/regex/#advanced-capture
      # renovate: datasource=github-releases depName=custom-components/ble_monitor
    CUSTOM_COMPONENT_BLE_MONITOR_VERSION=8.6.1 \
      # renovate: datasource=github-releases depName=thomasloven/hass-browser_mod
    CUSTOM_COMPONENT_BROWSER_MOD_VERSION=1.5.1 \
      # renovate: datasource=github-releases depName=leikoilja/ha-google-home
    CUSTOM_COMPONENT_GOOGLE_HOME_VERSION=v1.9.10 \
      # renovate: datasource=github-releases depName=PiotrMachowski/Home-Assistant-custom-components-Xiaomi-Cloud-Map-Extractor
    CUSTOM_COMPONENT_XIAOMI_CLOUD_MAP_EXTRACTOR_VERSION=v2.1.5 \
      # renovate: datasource=github-releases depName=shenxn/ha-dyson
    CUSTOM_COMPONENT_DYSON_LOCAL_VERSION=v0.16.2 \
      # renovate: datasource=github-releases depName=chomupashchuk/delete-file-home-assistant
    CUSTOM_COMPONENT_DELETE_FILE_VERSION=1.8 \
      # renovate: datasource=github-releases depName=PiotrMachowski/lovelace-xiaomi-vacuum-map-card
    CUSTOM_CARD_XIAOMI_VACUUM_MAP_VERSION=v2.0.10 \
      # renovate: datasource=github-releases depName=dylandoamaral/uptime-card
    CUSTOM_CARD_UPTIME_VERSION=v0.7.2 \
      # renovate: datasource=github-releases depName=kalkih/mini-graph-card
    CUSTOM_CARD_MINI_GRAPH_VERSION=v0.10.0 \
      # renovate: datasource=github-releases depName=marrobHD/tv-card
    CUSTOM_CARD_TV_REMOTE_VERSION=v0.2.0 \
      # renovate: datasource=github-releases depName=DurgNomis-drol/google_home_timers_card
    CUSTOM_CARD_GOOGLE_HOME_TIMERS_VERSION=v0.2.0

ENV \
    CUSTOM_CARD_XIAOMI_VACUUM_MAP_PATH=/local/external-cards/xiaomi-vacuum-map-card.js?version=${CUSTOM_CARD_XIAOMI_VACUUM_MAP_VERSION} \
    CUSTOM_CARD_UPTIME_PATH=/local/external-cards/uptime-card.js?version=${CUSTOM_CARD_UPTIME_VERSION} \
    CUSTOM_CARD_MINI_GRAPH_PATH=/local/external-cards/mini-graph-card-bundle.js?version=${CUSTOM_CARD_MINI_GRAPH_VERSION} \
    CUSTOM_CARD_TV_REMOTE_PATH=/local/external-cards/tv-card.js?version=${CUSTOM_CARD_TV_REMOTE_VERSION} \
    CUSTOM_CARD_GOOGLE_HOME_TIMERS_PATH=/local/external-cards/googletimers-card.js?version=${CUSTOM_CARD_GOOGLE_HOME_TIMERS_VERSION}

RUN \
    set -ex \
    && apk add --no-cache --virtual build-dep \
      git \
    && mkdir -p /opt/HA/config/custom_components/ \
    # ble_monitor
    && git clone https://github.com/custom-components/ble_monitor.git /tmp/ble_monitor \
    && cd /tmp/ble_monitor && git checkout $CUSTOM_COMPONENT_BLE_MONITOR_VERSION \
    && cd - && cp -r /tmp/ble_monitor/custom_components/* /opt/HA/config/custom_components/ \
    # browser_mod
    && git clone https://github.com/thomasloven/hass-browser_mod.git /tmp/browser_mod \
    && cd /tmp/browser_mod && git checkout $CUSTOM_COMPONENT_BROWSER_MOD_VERSION \
    && cd - && cp -r /tmp/browser_mod/custom_components/* /opt/HA/config/custom_components/ \
    # ha-google-home
    && git clone https://github.com/leikoilja/ha-google-home.git /tmp/ha-google-home \
    && cd /tmp/ha-google-home && git checkout $CUSTOM_COMPONENT_GOOGLE_HOME_VERSION \
    && cd - && cp -r /tmp/ha-google-home/custom_components/google_home /opt/HA/config/custom_components/ \
    # xiaomi-cloud-map-extractor
    && git clone https://github.com/PiotrMachowski/Home-Assistant-custom-components-Xiaomi-Cloud-Map-Extractor.git /tmp/xiaomi-cloud-map-extractor \
    && cd /tmp/xiaomi-cloud-map-extractor && git checkout $CUSTOM_COMPONENT_XIAOMI_CLOUD_MAP_EXTRACTOR \
    && cd - && cp -r /tmp/xiaomi-cloud-map-extractor/custom_components/xiaomi_cloud_map_extractor /opt/HA/config/custom_components/ \
    # dyson-local
    && git clone https://github.com/shenxn/ha-dyson.git /tmp/ha-dyson-local \
    && cd /tmp/ha-dyson-local && git checkout $CUSTOM_COMPONENT_DYSON_LOCAL_VERSION \
    && cd - && cp -r /tmp/ha-dyson-local/custom_components/dyson_local /opt/HA/config/custom_components/ \
    # delete-file
    && git clone https://github.com/chomupashchuk/delete-file-home-assistant.git /tmp/delete-file-home-assistant \
    && cd /tmp/delete-file-home-assistant && git checkout $CUSTOM_COMPONENT_DELETE_FILE_VERSION \
    && cd - && cp -r /tmp/delete-file-home-assistant/custom_components/* /opt/HA/config/custom_components/ \
    ## ----------  Cards  ----------
    && mkdir -p /HA-custom-www/external-cards/ \
    # Xiaomi vacuum map card
    && curl -fsSL "https://github.com/PiotrMachowski/lovelace-xiaomi-vacuum-map-card/releases/download/${CUSTOM_CARD_XIAOMI_VACUUM_MAP_VERSION}/xiaomi-vacuum-map-card.js" -o /HA-custom-www/external-cards/xiaomi-vacuum-map-card.js \
    # Uptime Card
    && curl -fsSL "https://github.com/dylandoamaral/uptime-card/releases/download/${CUSTOM_CARD_UPTIME_VERSION}/uptime-card.js" -o /HA-custom-www/external-cards/uptime-card.js \
    # Mini Graph Card
    && curl -fsSL "https://github.com/kalkih/mini-graph-card/releases/download/${CUSTOM_CARD_MINI_GRAPH_VERSION}/mini-graph-card-bundle.js" -o /HA-custom-www/external-cards/mini-graph-card-bundle.js \
    # TV remote Card
    && git clone https://github.com/marrobHD/tv-card.git /tmp/tv_remote_card \
    && cd /tmp/tv_remote_card && git checkout $CUSTOM_CARD_TV_REMOTE_VERSION \
    ### Temporal patch until: https://github.com/marrobHD/tv-card/pull/22
    # && git clone https://github.com/ZephireNZ/tv-card.git /tmp/tv_remote_card \
    # && cd /tmp/tv_remote_card && git checkout fix/2021.11 \
    && cd - && cp -r /tmp/tv_remote_card/tv-card*.js /HA-custom-www/external-cards/ \
    # Google Home Card
    && git clone https://github.com/DurgNomis-drol/google_home_timers_card.git /tmp/google_home_timers_card \
    && cd /tmp/google_home_timers_card && git checkout $CUSTOM_CARD_GOOGLE_HOME_TIMERS_VERSION \
    && cd - && cp -r /tmp/google_home_timers_card/googletimers-card.js /HA-custom-www/external-cards/ \
    && apk del build-dep

RUN \
    set -ex; \
    ## Create folder to save snapshots
    mkdir -p /tmp/homeassistant/snapshots


COPY prepare.sh /etc/cont-init.d/
