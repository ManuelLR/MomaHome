#!/bin/bash
#
## This script initialize homeassistant to reload module before load config
#
set -ex

echo "This script initialize homeassistant to reload module before load config"

# Move original config and try to load things without that config
mv /config/configuration.yaml /config/configuration.yaml.tmp
touch /config/configuration.yaml

set +e
echo "Starting fake HomeAssistant..."
/usr/local/bin/python3 -m homeassistant --config=/config/ &
process_pid=$!

set -e

sleep 10s

echo "Finishing fake HomeAssistant..."
kill -s SIGTERM $process_pid

mv /config/configuration.yaml.tmp /config/configuration.yaml


/usr/local/bin/hass -c /config/ --script check_config
