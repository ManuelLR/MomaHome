FROM homeassistant/home-assistant:2021.3.3

ENV \
    CUSTOM_COMPONENT_MITEMP_VERSION=1.2.0 \
    # syncthing => https://github.com/home-assistant/core/pull/38331
    CUSTOM_COMPONENT_SYNCTHING_VERSION=13b00d55914bb81c7be45af16b1328edd0ef9bb9 \
    CUSTOM_COMPONENT_GOOGLE_HOME=b51afaff56722c5b276000067bc8ea6e7941d651

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
    # ha-google-home
    && git clone https://github.com/leikoilja/ha-google-home.git /tmp/ha-google-home \
    && cd /tmp/ha-google-home && git checkout $CUSTOM_COMPONENT_GOOGLE_HOME \
    && cd - && cp -r /tmp/ha-google-home/custom_components/google_home /opt/HA/config/custom_components/ \
    && apk del build-dep

COPY prepare.sh /etc/cont-init.d/
