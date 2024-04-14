#!/usr/bin/with-contenv bash
#
## This script initialize homeassistant to reload module before load config
#
set -ex

echo "This script initialize homeassistant to reload module before load config"

CONFIG_PREFIX_PATH="${GITHUB_WORKSPACE:-}/config"

# Move original config and try to load things without that config
if [ -s ${CONFIG_PREFIX_PATH}/configuration.yaml ]; then
    mv ${CONFIG_PREFIX_PATH}/configuration.yaml ${CONFIG_PREFIX_PATH}/configuration.yaml.tmp
    touch ${CONFIG_PREFIX_PATH}/configuration.yaml
fi

echo "Starting checking HomeAssistant..."

set +e
/usr/local/bin/hass -c ${CONFIG_PREFIX_PATH}/ --script check_config --info=all > /tmp/firstCheckConfig.log 2>&1
firstCheckConfigStatus=$?
set -e

mv ${CONFIG_PREFIX_PATH}/configuration.yaml.tmp ${CONFIG_PREFIX_PATH}/configuration.yaml

if [ $firstCheckConfigStatus -ne 0 ]; then
    echo "Error analyzing the config. Returned error code was $firstCheckConfigStatus."
    echo "Is normal to have errors on the first try, nothing to worry about :)"
    # ## Not required to report the errors but if you want to debug it, here you have the lines
    # cat /tmp/firstCheckConfig.log
    # exit $firstCheckConfigStatus
fi

/usr/local/bin/hass -c ${CONFIG_PREFIX_PATH}/ --script check_config --info=all
