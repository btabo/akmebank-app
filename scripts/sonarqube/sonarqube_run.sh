#!/usr/bin/env bash

. "${ONE_PIPELINE_PATH}/tools/retry"
. "${ONE_PIPELINE_PATH}/internal/tools/logging"

if [[ "$PIPELINE_DEBUG" == 1 ]]; then
  trap env EXIT
  env
  set -x
fi

. /workspace/app/one-pipeline-config-repo/scripts/sonarqube/sonarqube_setup.sh

if [ "$SONAR_CONFIG" == "default" ]; then
  . /workspace/app/one-pipeline-config-repo/scripts/sonarqube/sonarqube_default.sh

  run_dind_instance
else
  . /workspace/app/one-pipeline-config-repo/scripts/sonarqube/sonarqube_instance.sh
fi

. /workspace/app/one-pipeline-config-repo/scripts/sonarqube/sonarqube_properties.sh
. /workspace/app/one-pipeline-config-repo/scripts/sonarqube/sonarqube_scan.sh
