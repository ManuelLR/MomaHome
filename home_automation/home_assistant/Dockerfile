FROM homeassistant/home-assistant:2021.1.4

ENV \
    CUSTOM_COMPONENT_MITEMP_VERSION=0.9.4 \
    # syncthing => https://github.com/home-assistant/core/pull/38331
    CUSTOM_COMPONENT_SYNCTHING_VERSION=6e9aeabba8e25f65abb8526f462dec2933fe0c1f

RUN \
    set -ex \
    && apk add --no-cache --virtual build-dep \
      git \
    && mkdir -p /opt/HA/config/custom_components/ \
    # ble_monitor
    && git clone https://github.com/custom-components/ble_monitor.git /tmp/mitemp \
    && cd /tmp/mitemp && git checkout $CUSTOM_COMPONENT_MITEMP_VERSION \
    && cd - && cp -r /tmp/mitemp/custom_components/* /opt/HA/config/custom_components/ \
    # syncthing
    && git clone https://github.com/zhulik/core.git /tmp/syncthing \
    && cd /tmp/syncthing && git checkout $CUSTOM_COMPONENT_SYNCTHING_VERSION \
    && cd - && cp -r /tmp/syncthing/homeassistant/components/syncthing /opt/HA/config/custom_components/ \
    && apk del build-dep

COPY prepare.sh /etc/cont-init.d/
