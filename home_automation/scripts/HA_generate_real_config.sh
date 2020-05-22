#!/bin/bash

# Move to script folder
cd $(dirname $(readlink -f $0))

set -ex

HA_CONFIG_PATH="${HA_CONFIG_PATH:-../home_assistant/config}"
GENERATED_CONFIG_PATH="${GENERATED_CONFIG_PATH:-__auto_generated-config}"
PACKAGED_CONFIG_PATH="${PACKAGED_CONFIG_PATH:-packages}"

cd "${HA_CONFIG_PATH}"

echo "Clean previous config (if any)"
rm -rf "${GENERATED_CONFIG_PATH}"

set +x
shopt -s globstar
for i in ${PACKAGED_CONFIG_PATH}/**/*.yaml; do
    FILE_TYPE="$(basename $i .yaml)"
    DST_LINK_FILE="${GENERATED_CONFIG_PATH}/${FILE_TYPE}"
    # Initialize config folder
    mkdir -p "${DST_LINK_FILE}"
    # Navigate to config folder
    cd "${DST_LINK_FILE}"

    # Get dirname
    FILE_PATH="$(dirname $i)"
    # Remove PACKAGED_CONFIG_PATH from dirname
    TRUNCATED_FILE_PATH="${FILE_PATH#$PACKAGED_CONFIG_PATH/}"
    # Replace / if multi-level folder
    LINK_FILE_NAME="${TRUNCATED_FILE_PATH//\//_-_}"

    # Generate link file
    ln -s "../../${i}" "${LINK_FILE_NAME}.yaml"
    echo "${DST_LINK_FILE}/${LINK_FILE_NAME}.yaml  -->  ${i}"
    cd - > /dev/null
done
