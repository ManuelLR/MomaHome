FROM homeassistant/home-assistant:2021.4.3

ENV \
    CUSTOM_COMPONENT_MITEMP_VERSION=1.6.0 \
    # syncthing => https://github.com/home-assistant/core/pull/38331
    CUSTOM_COMPONENT_SYNCTHING_VERSION=13b00d55914bb81c7be45af16b1328edd0ef9bb9 \
    CUSTOM_COMPONENT_GOOGLE_HOME=v1.4.0 \
    CUSTOM_CARD_UPTIME=v0.2.0 \
    CUSTOM_CARD_GOOGLE_HOME_TIMERS=v0.2.0

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
    ## ----------  Cards  ----------
    && mkdir -p /HA-custom-www/external-cards/ \
    # Uptime Card
    && curl -fsSL "https://github.com/dylandoamaral/uptime-card/releases/download/${CUSTOM_CARD_UPTIME}/uptime-card.js" -o /HA-custom-www/external-cards/uptime-card.js \
    # Google Home Card
    && git clone https://github.com/DurgNomis-drol/google_home_timers_card.git /tmp/google_home_timers_card \
    && cd /tmp/google_home_timers_card && git checkout $CUSTOM_CARD_GOOGLE_HOME_TIMERS \
    && cd - && cp -r /tmp/google_home_timers_card/googletimers-card.js /HA-custom-www/external-cards/ \
    && apk del build-dep

COPY prepare.sh /etc/cont-init.d/
