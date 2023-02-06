#!/usr/bin/env bash

if [[ -z $LOG_LEVEL ]]; then
    LOGGING="--log-level info"
else
    LOGGING="--log-level ${LOG_LEVEL}"
fi

cd $INSTALL_PATH
${BINARY_PATH}/openshift-install destroy cluster --dir ./ ${LOGGING}