FROM homeassistant/home-assistant:0.109.6

ENV CUSTOM_COMPONENT_MITEMP_VERSION=0.6.8

RUN \
    set -ex \
    && apk add --no-cache --virtual build-dep \
      git \
    && mkdir -p /opt/HA/config/custom_components/ \
    && git clone https://github.com/custom-components/sensor.mitemp_bt.git /tmp/mitemp \
    && cd /tmp/mitemp && git checkout $CUSTOM_COMPONENT_MITEMP_VERSION \
    && cd - && cp -r /tmp/mitemp/custom_components/* /opt/HA/config/custom_components/ \
    && apk del build-dep

RUN ls -alh /opt/HA/config/

COPY prepare.sh /etc/cont-init.d/

# COPY config/ /config
