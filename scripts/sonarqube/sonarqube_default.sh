#!/usr/bin/env bash

set_sonarqube_settings() {
  read -r SONAR_HOST_URL <<< "$1"
  read -r SONAR_USER <<< "$2"; if [ "$SONAR_USER" == "-" ]; then read -r SONAR_USER; fi
  read -r SONAR_PASS <<< "$3"

  export SONAR_HOST_URL
  export SONAR_USER
  export SONAR_PASS
}

collect_failed_evidence() {
  list_repos | while IFS= read -r repo ; do
    collect-evidence \
      --tool-type "sonarqube" \
      --evidence-type "com.ibm.static_scan" \
      --asset-type "repo" \
      --asset-key "${repo}" \
      --status "failure"
  done
}

run_dind_instance() {
  local -i attempt=1
  local -r sonar_instance_name="cocoa-sonarqube-"$(date +%s%3N)
  local -r sonar_image="$(get_env sonarqube-instance-image)"
  local -i -r retry_sleep=$(get_env "static-scan-retry-sleep" 3)
  local -i -r retry_count=$(get_env "static-scan-retry-count" 10)

  banner "Setting up SonarQube container"
  docker run -d -t -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true -p 9000:9000 --name "$sonar_instance_name" "$sonar_image"

  docker network create sonarqube-network
  until [ "$(docker inspect -f "{{.State.Running}}" "${sonar_instance_name}")" == "true" ]; do
    if [ $attempt -eq "$retry_count" ]; then
      debug "\nAttempt $attempt. failed and there are no more attempts left, the container couldn't start."

      collect_failed_evidence
      exit 1
    fi

    debug "Waiting for container to start"
    sleep "$retry_sleep"
    ((attempt++))
  done;

  sonar_host_url=$(docker inspect "${sonar_instance_name}" | jq -r '.[].NetworkSettings.Networks.bridge.IPAddress')

  set_sonarqube_settings \
    "http://${sonar_host_url}:9000" \
    "admin" \
    "admin"
}
