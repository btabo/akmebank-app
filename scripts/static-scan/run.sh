#!/usr/bin/env bash
source "${ONE_PIPELINE_PATH}/internal/tools/logging"


debug "This stage is the static-scan stage. For more information: https://cloud.ibm.com/docs/devsecops?topic=devsecops-cd-devsecops-ci-pipeline#devsecops-ci-pipeline-static-codescan"

if [ -z "$(get_env opt-in-sonar "")" ]; then
  debug "If you want to enable the SonarQube Scan, add 'opt-in-sonar' parameter to your pipeline with any value."
fi

if [ -n "$(get_env opt-in-sonar "")" ]; then
  banner "Running SonarQube Scan."
  chmod +x /workspace/app/one-pipeline-config-repo/scripts/sonarqube
  chmod +x /workspace/app/one-pipeline-config-repo/scripts/sonarqube/*
  /workspace/app/one-pipeline-config-repo/scripts/sonarqube/sonarqube_run.sh
fi

if [ -n "$(get_env "STATIC_SCAN_FAILURE" "")" ]; then
  exit 1
fi
