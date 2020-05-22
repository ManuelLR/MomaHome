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

set +e
echo "Starting fake HomeAssistant..."
# /usr/local/bin/python3 -m homeassistant --config=/config/ &

# process_pid=$!

# set -e

# sleep 10s

# echo "Finishing fake HomeAssistant..."
# kill -s SIGTERM $process_pid

/usr/local/bin/hass -c ${CONFIG_PREFIX_PATH}/ --script check_config


mv ${CONFIG_PREFIX_PATH}/configuration.yaml.tmp ${CONFIG_PREFIX_PATH}/configuration.yaml


/usr/local/bin/hass -c ${CONFIG_PREFIX_PATH}/ --script check_config
