#!/usr/bin/with-contenv bash
#
## This script initialize homeassistant to reload module before load config
#
set -ex

echo "This script initialize homeassistant to reload module before load config"

## Resolve config path for both:
## - Normal container runtime (bind-mount at /config)
## - GitHub Actions (workspace mounted at $GITHUB_WORKSPACE)
if [ -d "/config" ]; then
    CONFIG_PREFIX_PATH="/config"
elif [ -n "${GITHUB_WORKSPACE:-}" ] && [ -d "${GITHUB_WORKSPACE}/home_automation/home_assistant/config" ]; then
    CONFIG_PREFIX_PATH="${GITHUB_WORKSPACE}/home_automation/home_assistant/config"
elif [ -n "${GITHUB_WORKSPACE:-}" ] && [ -d "${GITHUB_WORKSPACE}/config" ]; then
    CONFIG_PREFIX_PATH="${GITHUB_WORKSPACE}/config"
else
    CONFIG_PREFIX_PATH="/config"
fi

## Ensure static assets are available under /local (= /config/www)
mkdir -p "${CONFIG_PREFIX_PATH}/www/external-cards"
if [ -d "/HA-custom-www/external-cards" ]; then
    cp -R /HA-custom-www/external-cards/. "${CONFIG_PREFIX_PATH}/www/external-cards/"
fi

## Some dashboards use /local/my_config/*
mkdir -p "${CONFIG_PREFIX_PATH}/www/my_config"
if [ -d "/HA-custom-www/my_config" ]; then
    cp -R /HA-custom-www/my_config/. "${CONFIG_PREFIX_PATH}/www/my_config/"
fi
if [ -d "/HA-custom-www/my-config" ]; then
    cp -R /HA-custom-www/my-config/. "${CONFIG_PREFIX_PATH}/www/my_config/"
fi

# Move original config and try to load things without that config
if [ -s ${CONFIG_PREFIX_PATH}/configuration.yaml ]; then
    mv ${CONFIG_PREFIX_PATH}/configuration.yaml ${CONFIG_PREFIX_PATH}/configuration.yaml.tmp
    touch ${CONFIG_PREFIX_PATH}/configuration.yaml
fi

echo "Starting checking HomeAssistant..."

set +e
/usr/local/bin/hass --config ${CONFIG_PREFIX_PATH}/ --script check_config --config=${CONFIG_PREFIX_PATH}/ --info=all > /tmp/firstCheckConfig.log 2>&1
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

/usr/local/bin/hass --config ${CONFIG_PREFIX_PATH}/ --script check_config --config=${CONFIG_PREFIX_PATH}/ --info=all
