#!/usr/bin/env bash

export IBMCLOUD_API_KEY
export IBMCLOUD_TOOLCHAIN_ID
export IBMCLOUD_IKS_REGION
export IBMCLOUD_IKS_CLUSTER_NAME
export IBMCLOUD_IKS_CLUSTER_NAMESPACE
export REGISTRY_URL
export IMAGE_PULL_SECRET_NAME
export HOME
export BREAK_GLASS

if [ -f /config/api-key ]; then
  IBMCLOUD_API_KEY="$(cat /config/api-key)" # pragma: allowlist secret
else
  IBMCLOUD_API_KEY="$(cat /config/ibmcloud-api-key)" # pragma: allowlist secret
fi

HOME=/root
IBMCLOUD_TOOLCHAIN_ID="$(jq -r .toolchain_guid /toolchain/toolchain.json)"
IBMCLOUD_IKS_REGION="$(awk -F ":" '{print $NF}' < /config/dev-region)"
IBMCLOUD_IKS_CLUSTER_NAMESPACE="$(cat /config/dev-cluster-namespace)"
IBMCLOUD_IKS_CLUSTER_NAME="$(cat /config/cluster-name)"
# Use the first microservice image to retrieve the regitrsy url
REGISTRY_URL="$(load_artifact account-command-ms name |  awk -F/ '{print $1}')"
IMAGE_PULL_SECRET_NAME="ibmcloud-toolchain-${IBMCLOUD_TOOLCHAIN_ID}-${REGISTRY_URL}"
BREAK_GLASS=$(cat /config/break_glass || echo "")

if [[ -n "${BREAK_GLASS}" ]]; then
  export KUBECONFIG
  KUBECONFIG=/config/cluster-cert
else
  IBMCLOUD_IKS_REGION=$(echo "${IBMCLOUD_IKS_REGION}" | awk -F ":" '{print $NF}')
  ibmcloud login -r "${IBMCLOUD_IKS_REGION}"
  ibmcloud ks cluster config --cluster "${IBMCLOUD_IKS_CLUSTER_NAME}"

  ibmcloud ks cluster get --cluster "${IBMCLOUD_IKS_CLUSTER_NAME}" --json > "${IBMCLOUD_IKS_CLUSTER_NAME}.json"
  # If the target cluster is openshift then make the appropriate additional login with oc tool
  if which oc > /dev/null && jq -e '.type=="openshift"' "${IBMCLOUD_IKS_CLUSTER_NAME}.json" > /dev/null; then
    echo "${IBMCLOUD_IKS_CLUSTER_NAME} is an openshift cluster. Doing the appropriate oc login to target it"
    oc login -u apikey -p "${IBMCLOUD_API_KEY}"
  fi
fi
