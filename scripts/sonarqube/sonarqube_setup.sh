#!/usr/bin/env bash

export IKS_BETA_VERSION=1

IBMCLOUD_API=$(get_env ibmcloud-api "https://cloud.ibm.com")
SONAR_CONFIG="$(get_env sonarqube-config "")"

if [ -f /config/api-key ]; then
  IBMCLOUD_API_KEY="$(cat /config/api-key)" # pragma: allowlist secret
else
  IBMCLOUD_API_KEY="$(cat /config/ibmcloud-api-key)" # pragma: allowlist secret
fi

SONAR_INSTANCE_IMAGE="icr.io/continuous-delivery/toolchains/devsecops/sonarqube@sha256:836e3b543f34c36438456e0c7a03fef314cbb77741e790920aa2565d83f0c9e4"
SONAR_SCANNER_IMAGE="icr.io/continuous-delivery/toolchains/devsecops/sonar-scanner-cli@sha256:af782cf68bbfe32982aac08e3215d95f57c9ce49444ab8bfa017819ba4905548"

set_env sonarqube-instance-image "$SONAR_INSTANCE_IMAGE"
set_env sonarqube-scanner-image "$SONAR_SCANNER_IMAGE"

export SONAR_INSTANCE
export SONAR_NAMESPACE
export SONAR_HOST_URL
export SONAR_USER
export SONAR_PASS
export SONAR_CONFIGURED
export SONAR_CONFIG
export SONAR_TOKEN

read -r SONAR_CONFIGURED <<< "$(get_env sonarqube | jq . 2>/dev/null)"

if [ -n "$SONAR_CONFIGURED" ] || [ "$SONAR_CONFIG" == "custom" ]; then
  read -r SONAR_INSTANCE <<< "$(get_env sonarqube | jq -r '.parameters.name')"
  read -r SONAR_HOST_URL <<< "$(get_env sonarqube | jq -r '.parameters.dashboard_url' | sed 's:/*$::')"
  read -r SONAR_USER <<< "$(get_env sonarqube | jq -r '.parameters.user_login')"
  read -r SONAR_PASS <<< "$(get_env sonarqube | jq -r '.parameters.user_password')"

  # if user field left empty, this means the password field should contain the token instead of a password
  if [[ -z "$SONAR_USER" && -n "$SONAR_PASS" ]]; then
    banner "\nUsing SonarQube token from tool integration"
    SONAR_TOKEN=$SONAR_PASS
    unset SONAR_PASS
    echo "$SONAR_TOKEN" > /tmp/sonarqube-token
  fi

elif [[ -n "$BREAK_GLASS" ]]; then
  debug "Break-Glass mode is on, skipping the rest of the task..."

  exit 0
elif [ "$SONAR_CONFIG" == "default" ]; then
  banner "Default configuration will be used, a SonarQube scan will run Docker-in-Docker and the instance won't be available after the run."
else
  SONAR_HOST_URL=http://localhost:9001
  IBMCLOUD_IKS_REGION="$(get_env dev-region | awk -F ":" '{print $NF}')"
  IBMCLOUD_IKS_CLUSTER_NAME="$(get_env cluster-name)"
  banner "\nLogin to IBM Cloud"
  banner "======================\n"

  ibmcloud config --check-version false
  retry 5 2 \
    ibmcloud login -r "$IBMCLOUD_IKS_REGION" --apikey @/config/ibmcloud-api-key -a "$IBMCLOUD_API"
  exit_code=$?

  if [ $exit_code -ne 0 ]; then
    error "Could not log in to the IBM Cloud"
    exit $exit_code
  fi

  banner "\nDownload the Kubernetes configuration files to connect to your cluster by using 'kubectl' commands"
  banner "======================\n"
  retry 5 2 \
    ibmcloud ks cluster config --cluster "$IBMCLOUD_IKS_CLUSTER_NAME"
  exit_code=$?

  if [ $exit_code -ne 0 ]; then
    error "\nCould not download the Kubernetes configuration files by using 'kubectl' commands"
    exit $exit_code
  fi

  read -r CONFIGURED_NAMESPACE <<< "$(get_env sonarqube-namespace "")"
  SONAR_NAMESPACE="${CONFIGURED_NAMESPACE:-"default"}"

  if [[ "$SONAR_NAMESPACE" != "default" ]]; then
    kubectl get namespaces | grep "^$SONAR_NAMESPACE\b"
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
      error "The following SonarQube namespace does not exist: \"$SONAR_NAMESPACE\"."
      debug "Make sure that the namespace provided with the environment properties is created or use the default namespace instead.\n"
      exit $exit_code
    fi
  fi

  SONAR_INSTANCE=$(kubectl get deployment -n "$SONAR_NAMESPACE" | grep "cocoa-sonarqube")

  if [ "$SONAR_INSTANCE" ]; then
    SONAR_INSTANCE_NAME=$(kubectl get deployment -n "$SONAR_NAMESPACE" | grep "cocoa-sonarqube" | awk 'FNR == 1 {print $1}')

    kubectl get secret "$SONAR_INSTANCE_NAME" -n "$SONAR_NAMESPACE" -o jsonpath='{.data.token}' | base64 --decode > /tmp/sonarqube-token
    if [ $exit_code -ne 0 ]; then
      error "Could not get \"$SONAR_INSTANCE_NAME\" sonarqube secret"
      exit $exit_code
    fi
  fi
fi
