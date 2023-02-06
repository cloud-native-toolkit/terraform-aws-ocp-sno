#!/bin/bash

set -e

INPUT=$(tee)

# echo ${INPUT}

# Get bin_dir to be able to use jq
BIN_DIR=$(echo "${INPUT}" | grep "bin_dir" | sed -E 's/.*"bin_dir": ?"([^"]+)".*/\1/g')

# echo "Binary directory is : ${BIN_DIR}"

# Parse input
eval "$(echo "${INPUT}" | ${BIN_DIR}/jq -r '@sh "LOG_FILE=\(.log_file) METADATA_FILE=\(.metadata_file) KUBECONFIG_FILE=\(.kubeconfig_file)"')"

# Set config file path
CONFIGPATH="$(pwd ${LOG_FILE})"

# Get console URL info from the log file
CONSOLEURL=$(cat ${LOG_FILE} | grep "https://console-openshift-console" | tail -1 | egrep -o 'https?://[^ ]+' | sed 's/"//g')

# Get the server version from the openshift log
SERVER_VERSION=$(cat ${LOG_FILE} | grep "OpenShift Installer" | tail -1 | egrep -o 'OpenShift In[^"]+' | awk '{print $3}')

# Get credentials from the log file
USER=$(cat ${LOG_FILE} | grep "and password" | tail -1 | egrep -o 'user:[^,]+' | sed 's/\\"//g' | awk '{print $2}')
PWD=$(cat ${LOG_FILE} | grep "and password" | tail -1 | egrep -o 'password:[^,]+' | sed 's/\\"//g' | sed 's/"//g' | awk '{print $2}')

# Get the cluster id and infra id from the metadata
eval "$(cat ${METADATA_FILE} | ${BIN_DIR}/jq -r '@sh "CLUSTERID=\(.clusterID) INFRAID=\(.infraID)"')"

# Get the server URL from the kubeconfig file
SERVER_URL="$(${BIN_DIR}/yq4 eval '.clusters[].cluster.server' ${KUBECONFIG_FILE})"

# Set server token to empty as none is set at this stage of the build
SERVER_TOKEN=""

# Obtain the base domain from kubeconfig
CLUSTER_DOMAIN="$(${BIN_DIR}/yq4 eval '.clusters[].cluster.server' ${KUBECONFIG_FILE} | sed 's/https\:\/\/api.//g' | sed 's/\:6443//g')"

${BIN_DIR}/jq --null-input \
    --arg consoleurl "${CONSOLEURL}" \
    --arg user "${USER}" \
    --arg pwd "${PWD}" \
    --arg clusterid "${CLUSTERID}" \
    --arg infraid "${INFRAID}" \
    --arg server_version "${SERVER_VERSION}" \
    --arg serverurl "${SERVER_URL}" \
    --arg server_token "${SERVER_TOKEN}" \
    --arg cluster_domain "${CLUSTER_DOMAIN}" \
    '{"consoleURL": $consoleurl, "kubeadminUsername": $user, "kubeadminPassword": $pwd, "clusterID": $clusterid, "infraID": $infraid, "serverVersion": $server_version, "serverURL": $serverurl, "serverToken": $server_token, "clusterDomain": $cluster_domain }'
