#!/bin/bash
#
## This script initialize homeassistant to reload module before load config
#
set -ex

echo "This script initialize homeassistant to reload module before load config"

CONFIG_PREFIX_PATH="${GITHUB_WORKSPACE:-}/config"

# Move original config and try to load things without that config
mv ${CONFIG_PREFIX_PATH}/configuration.yaml ${CONFIG_PREFIX_PATH}/configuration.yaml.tmp
touch ${CONFIG_PREFIX_PATH}/configuration.yaml

echo "Starting checking HomeAssistant..."

/usr/local/bin/hass -c ${CONFIG_PREFIX_PATH}/ --script check_config > /dev/null

mv ${CONFIG_PREFIX_PATH}/configuration.yaml.tmp ${CONFIG_PREFIX_PATH}/configuration.yaml

/usr/local/bin/hass -c ${CONFIG_PREFIX_PATH}/ --script check_config --info=all
