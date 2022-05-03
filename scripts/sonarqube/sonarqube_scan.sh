#!/usr/bin/env bash

curl_admin() {
  if [[ -n "${SONAR_TOKEN}" ]]; then
    curl --fail --silent --show-error --location "$@" \
      --config - << EOF
      --user "${SONAR_TOKEN}:"
EOF

    exit_code=$?
  else
    curl --fail --silent --show-error --location "$@" \
      --config - << EOF
      --user "${SONAR_USER}:${SONAR_PASS}"
EOF

    exit_code=$?
  fi

  if [ $exit_code -ne 0 ]; then
    exit $exit_code
  fi
}

get_system_status() {
  curl_admin --max-time 5 "${SONAR_HOST_URL}/api/system/status" | jq -r .status
}

get_task_status() {
  task_id=$1
  curl_admin "${SONAR_HOST_URL}/api/ce/task?id=${task_id}" | jq -r .task.status
}

sonarqube_status_check() {
  local -i attempt=1
  local -i -r retry_sleep=$(get_env "static-scan-retry-sleep" 10)
  local -i -r retry_count=$(get_env "static-scan-retry-count" 30)
  local SONAR_HEALTH

  SONAR_HEALTH=$(get_system_status)

  while [[ "$SONAR_HEALTH" != "UP" ]]; do
    if [ $attempt -eq "$retry_count" ]; then
      debug "\nAttempt $attempt. failed and there are no more attempts left, SonarQube is not up or the given credentials are not valid."
      exit 1
    fi

    banner "$attempt. attempt checking SonarQube startup failed... Retry in ${retry_sleep}s..."
    sleep "$retry_sleep"
    SONAR_HEALTH=$(get_system_status)
    ((attempt++))
  done

  banner "SonarQube instance is up and running!"
}

create_sonarqube_token() {
  declare -r -x ONE_TIME_TOKEN_NAME=$(date +%s%3N)

  curl_admin -X POST "${SONAR_HOST_URL}/api/user_tokens/generate?name=${ONE_TIME_TOKEN_NAME}" | jq -r '.token' > /tmp/sonarqube-token

  if [ -s /tmp/sonarqube-token ] && [ -z "$SONAR_CONFIGURED" ] && [ "$SONAR_CONFIG" != "default" ]; then
    kubectl create secret generic "$SONAR_INSTANCE_NAME" -n "$SONAR_NAMESPACE" --from-file=token=/tmp/sonarqube-token
    exit_code=$?

    if [ $exit_code -ne 0 ]; then
      error "Could not create \"$SONAR_INSTANCE_NAME\" secret\n"
      exit $exit_code
    fi
  fi
}

publish_sonar_to_doi() {
  if [[ -n "$(get_env BREAK_GLASS "")" ]]; then
    banner "Break-Glass mode is on, skipping pushing scan results to doi\n"
    return
  fi

  if [ -z "$DOI_TOOLCHAIN_ID" ]; then
    DOI_TOOLCHAIN_ID=$(get_env TOOLCHAIN_ID)
  fi

  local -r ibmcloud_api=$(get_env ibmcloud-api "https://cloud.ibm.com")
  local -r buildnumber="$(get_env doi-buildnumber "$BUILD_NUMBER")"
  local -r logicalappname="$(get_env doi-logicalappname "$name")"

  # Use `doi-ibmcloud-api-key` if present, if not, fall back to `ibmcloud-api-key`
  ibmcloud_api_key_name="/config/ibmcloud-api-key"
  if [[ -s "/config/doi-ibmcloud-api-key" ]]; then
    ibmcloud_api_key_name="/config/doi-ibmcloud-api-key"
  fi

  ibmcloud config --check-version false
  retry 5 2 \
    ibmcloud login -r "$IBMCLOUD_IKS_REGION" --apikey @"$ibmcloud_api_key_name" -a "$ibmcloud_api"
  exit_code=$?

  if [ $exit_code -ne 0 ]; then
    error "Could not log in to the IBM Cloud\n"
    exit $exit_code
  fi

  retry 5 5 \
    ibmcloud doi publishtestrecord \
    --logicalappname "$logicalappname" \
    --buildnumber "$buildnumber" \
    --toolchainid="$DOI_TOOLCHAIN_ID" \
    --filelocation "${SONAR_DIR}/report-task.txt" \
    --type sonarqube \
    --sqtoken "$(cat /tmp/sonarqube-token)"
}

check_sonar_scan_status() {
  sonar_task_id=$(grep 'ceTaskId' "${SONAR_DIR}/report-task.txt" | awk -F'[=]' '{print $2}')
  sonar_task_status=$(get_task_status "${sonar_task_id}")

  while [[ "$sonar_task_status" = "PENDING" || "$sonar_task_status" = "IN_PROGRESS" ]]; do
    sonar_task_status=$(get_task_status "${sonar_task_id}")
  done

  if [[ "$sonar_task_status" != "SUCCESS" ]]; then
    error "The SonarQube scan with the task ID of ${sonar_task_id} was not successful."
    exit 1
  fi
}

banner "\nSonarQube Status Check"
banner "=====================\n"
sonarqube_status_check

if [ ! -f /tmp/sonarqube-token ]; then
  banner "\nCreate SonarQube Token"
  banner "=====================\n"
  create_sonarqube_token
fi

list_repos | while IFS= read -r repo ; do
  url="$(load_repo "$repo" url)"
  name=$(echo "$url" | cut -f5 -d/)
  path="$(load_repo "$repo" path)"

  mkdir -p "${WORKSPACE}/sonar_scan/$name"
  SONAR_DIR="${WORKSPACE}/sonar_scan/$name"

  #
  # store result and attachment for asset-based evidence locker
  #
  evidence_params=(
    --tool-type "sonarqube" \
    --evidence-type "com.ibm.static_scan" \
    --asset-type "repo" \
    --asset-key "${repo}"
  )

  banner "\nScanner"
  banner "=====================\n"
  cd "$WORKSPACE"/"$path" || exit

  sonarqube_scanner_image="$(get_env sonarqube-scanner-image)"

  SONAR_PROJECT_KEY=$(< "$WORKSPACE"/"$path"/sonar-project.properties grep sonar.projectKey | cut -d "=" -f2)

  sonarqube_scan_command=$(get_env sonarqube-scan-command "docker run --network host -v \"$SONAR_DIR\":/usr/sonar_scan -v \"$WORKSPACE/$path\":/usr/src \"$sonarqube_scanner_image\" sonar-scanner -Dsonar.working.directory=/usr/sonar_scan")
  echo "executing the sonarqube scan command: $sonarqube_scan_command"
  eval $sonarqube_scan_command

  exit_code=$?
  if [ $exit_code -ne 0 ]; then
    error "Could not run the Sonar Scanner\n"

    evidence_params+=(
      --status "failure"
    )
    collect-evidence "${evidence_params[@]}"

    exit $exit_code
  fi

  banner "\nScanner status check"
  banner "=====================\n"
  check_sonar_scan_status

  banner "\nIssues"
  banner "=====================\n"
  PROJECT_ISSUES=$(curl_admin "${SONAR_HOST_URL}/api/issues/search?componentKeys=${SONAR_PROJECT_KEY}")
  echo "$PROJECT_ISSUES" | jq '.'

  banner "\nQuality gate status"
  banner "======================\n"
  PROJECT_STATUS=$(curl_admin "${SONAR_HOST_URL}/api/qualitygates/project_status?projectKey=${SONAR_PROJECT_KEY}")
  echo "$PROJECT_STATUS" | jq '.'

  banner "\nPublish to DOI"
  banner "======================\n"
  publish_sonar_to_doi

  # export results
  echo "$PROJECT_ISSUES" | jq '.' > "${SONAR_DIR}/app_issues"
  echo "$PROJECT_STATUS" | jq '.' > "${SONAR_DIR}/app_quality_status"

  # if we created a one-time token, revoke it at the server to clean up after ourselves
  if [[ -n "$ONE_TIME_TOKEN_NAME" ]]; then
    curl_admin -X POST "${SONAR_HOST_URL}/api/user_tokens/revoke?name=${ONE_TIME_TOKEN_NAME}"
  fi

  if [ -s "${SONAR_DIR}/app_issues" ]; then
    save_result static-scan "${SONAR_DIR}/app_issues"
    evidence_params+=(
      --attachment "${SONAR_DIR}/app_issues"
    )
  fi
  if [ -s "${SONAR_DIR}/app_quality_status" ]; then
    save_result static-scan "${SONAR_DIR}/app_quality_status"
    evidence_params+=(
      --attachment "${SONAR_DIR}/app_quality_status"
    )
  fi

  STATIC_SCAN_STATUS=$(echo "$PROJECT_STATUS" | jq -r '.projectStatus.status' )
  if [[ "${STATIC_SCAN_STATUS}" = "OK" ]] || [[ "${STATIC_SCAN_STATUS}" = "NONE" ]] || [[ "${STATIC_SCAN_STATUS}" = "WARN" ]]; then
    status="success"
  else
    set_env STATIC_SCAN_FAILURE "true"
    status="failure"
  fi

  evidence_params+=(
    --status "${status}"
  )

  collect-evidence "${evidence_params[@]}"
done

unset SONAR_PASS

if [ -n "$SONAR_POD_NAME" ]; then
  banner "======================"
  debug "You can connect to SonarQube by port-forwarding."
  banner "For example you can access SonarQube at \"$SONAR_HOST_URL\" after running the following command on your computer: "
  debug "kubectl port-forward --address 0.0.0.0 pod/\"$SONAR_POD_NAME\"  9001:9000 -n \"$SONAR_NAMESPACE\""
  debug "the default username/password is admin/admin, if not set otherwise"
  banner "======================"
elif [ "$SONAR_CONFIG" == "default" ]; then
  banner "======================"
  banner "SonarQube dashboard is not available with the default Docker-in-Docker run."
  banner "======================"
else
  banner "======================"
  banner "SonarQube is available at: \"$SONAR_HOST_URL\" "
  banner "======================"
fi
