#!/usr/bin/env bash

create_sonarqube_instance() {
  name=$1
  namespace=$2
  sonarqube_instance_image="$(get_env sonarqube-instance-image)"

  kubectl create -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
 name: $name
 namespace: $namespace
 labels:
   app: $name
spec:
 replicas: 1
 selector:
   matchLabels:
     app: $name
 template:
   metadata:
     labels:
       app: $name
   spec:
     containers:
     - name: $name
       imagePullPolicy: IfNotPresent
       image: $sonarqube_instance_image
       resources:
         requests:
           memory: 1024Mi
         limits:
           memory: 2048Mi
       startupProbe:
         httpGet:
           path: /api/system/status
           port: 9000
         initialDelaySeconds: 90
         failureThreshold: 30
         periodSeconds: 10
EOF
}

check_if_deployment_running() {
  instance_name=$1
  instance_namespace=$2

  if ! kubectl rollout status deployment/"$instance_name" -n "$instance_namespace"; then
    debug "\nDeployment: $instance_name not available."
    debug "Consider fixing the problem after running the 'kubectl get deployment $instance_name -n $instance_namespace' command."
    debug "If you want to try again with a new deployment, please delete the deployment before running a new pipeline with the following command:"
    debug "kubectl delete deployment $instance_name -n $instance_namespace"
    exit 1
  fi
}

port_forward() {
  instance_name=$1
  instance_namespace=$2
  pod_name=$(kubectl get pods -n "$instance_namespace" | grep "$instance_name" | awk 'FNR == 1 {print $1}')
  export SONAR_POD_NAME=$pod_name
  # TODO: the logs of the port-forwarding should be redirected
  # (and only printed in PIPELINE_DEBUG mode) so it won't pollute the actual logs
  kubectl port-forward --address 0.0.0.0 pod/"${pod_name}" 9001:9000 -n "$instance_namespace" &
}

set_sonarqube_settings() {
  read -r SONAR_HOST_URL <<< "$1"
  read -r SONAR_USER <<< "$2"; if [ "$SONAR_USER" == "-" ]; then read -r SONAR_USER; fi
  read -r SONAR_PASS <<< "$3"

  export SONAR_HOST_URL
  export SONAR_USER
  export SONAR_PASS
}

if [ -n "$SONAR_CONFIGURED" ] || [ "$SONAR_CONFIG" == "custom" ]; then
  banner "\nSonarQube configured, using the SonarQube integration..."
  banner "======================\n"
elif [ "$SONAR_INSTANCE" ]; then
  banner "\n\nUsing the previously created SonarQube instance..."
  banner "======================\n"

  port_forward "$SONAR_INSTANCE_NAME" "$SONAR_NAMESPACE"
  exit_code=$?
  set_sonarqube_settings "$SONAR_HOST_URL" "-" "" < /tmp/sonarqube-token
else
  banner "\nCreating new SonarQube instance..."
  banner "======================\n"
  export SONAR_INSTANCE_NAME
  SONAR_INSTANCE_NAME="cocoa-sonarqube-"$(date +%s%3N)

  create_sonarqube_instance "$SONAR_INSTANCE_NAME" "$SONAR_NAMESPACE"
  exit_code=$?
  if [ $exit_code -ne 0 ]; then
    error "\n Could not create \"$SONAR_INSTANCE_NAME\" SonarQube instance"
    exit $exit_code
  fi
  check_if_deployment_running "$SONAR_INSTANCE_NAME" "$SONAR_NAMESPACE"
  port_forward "$SONAR_INSTANCE_NAME" "$SONAR_NAMESPACE"

  set_sonarqube_settings \
    "$SONAR_HOST_URL" \
    "admin" \
    "admin"
fi
