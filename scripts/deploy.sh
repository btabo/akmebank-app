#!/usr/bin/env bash

if kubectl get namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE"; then
  echo "Namespace ${IBMCLOUD_IKS_CLUSTER_NAMESPACE} found!"
else
  kubectl create namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE";
fi

if kubectl get secret -n "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" "$IMAGE_PULL_SECRET_NAME"; then
  echo "Image pull secret ${IMAGE_PULL_SECRET_NAME} found!"
else
  if [[ -n "$BREAK_GLASS" ]]; then
    kubectl create -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $IMAGE_PULL_SECRET_NAME
  namespace: $IBMCLOUD_IKS_CLUSTER_NAMESPACE
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: $(jq .parameters.docker_config_json /config/artifactory)
EOF
  else
    kubectl create secret docker-registry \
      --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" \
      --docker-server "$REGISTRY_URL" \
      --docker-password "$IBMCLOUD_API_KEY" \
      --docker-username iamapikey \
      --docker-email ibm@example.com \
      "$IMAGE_PULL_SECRET_NAME"
  fi
fi

if kubectl get serviceaccount -o json default --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" | jq -e 'has("imagePullSecrets")'; then
  if kubectl get serviceaccount -o json default --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" | jq --arg name "$IMAGE_PULL_SECRET_NAME" -e '.imagePullSecrets[] | select(.name == $name)'; then
    echo "Image pull secret $IMAGE_PULL_SECRET_NAME found in $IBMCLOUD_IKS_CLUSTER_NAMESPACE"
  else
    echo "Adding image pull secret $IMAGE_PULL_SECRET_NAME to $IBMCLOUD_IKS_CLUSTER_NAMESPACE"
    kubectl patch serviceaccount \
      --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" \
      --type json \
      --patch '[{"op": "add", "path": "/imagePullSecrets/-", "value": {"name": "'"$IMAGE_PULL_SECRET_NAME"'"}}]' \
      default
  fi
else
  echo "Adding image pull secret $IMAGE_PULL_SECRET_NAME to $IBMCLOUD_IKS_CLUSTER_NAMESPACE"
  kubectl patch serviceaccount \
    --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" \
    --patch '{"imagePullSecrets":[{"name":"'"$IMAGE_PULL_SECRET_NAME"'"}]}' \
    default
fi


# Create the COS secret using COS information
export COS_API_KEY=$(get_env AKME_COS_API_KEY)
export COS_SERVICE_INSTANCE_ID=$(get_env AKME_COS_SERVICE_INSTANCE_ID "crn:v1:bluemix:public:cloud-object-storage:global:a/80c84878b3b02b88be3f836f0534b03e:0693b059-6e56-4eab-af12-7dddb1248c6d:bucket:akme-test-bucket")
export COS_ENDPOINT_URL=$(get_env AKME_COS_ENDPOINT_URL "s3.eu-de.cloud-object-storage.appdomain.cloud")
export COS_LOCATION=$(get_env AKME_COS_LOCATION "eu-de")
export COS_ACCOUNTS_BUCKET=$(get_env AKME_COS_ACCOUNTS_BUCKET "akme-account-bucket")
export COS_USERS_BUCKET=$(get_env AKME_COS_USERS_BUCKET "akme-users-bucket")

COS_SECRET="cos-secret"
if kubectl get secret -n "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" $COS_SECRET; then
  echo "Patching $COS_SECRET in namespace $IBMCLOUD_IKS_CLUSTER_NAMESPACE"
  kubectl create secret --namespace "${IBMCLOUD_IKS_CLUSTER_NAMESPACE}" generic $COS_SECRET \
    --save-config=true --dry-run=client \
    --from-literal=API_KEY="${COS_API_KEY}" \
    --from-literal=SERVICE_INSTANCE_ID="${COS_SERVICE_INSTANCE_ID}" \
    --from-literal=ENDPOINT_URL="${COS_ENDPOINT_URL}" \
    --from-literal=LOCATION="${COS_LOCATION}" \
    --from-literal=ACCOUNTS_BUCKET="${COS_ACCOUNTS_BUCKET}" \
    --from-literal=USERS_BUCKET="${COS_USERS_BUCKET}" \
    -o yaml | kubectl apply -f -
else
  echo "Creating $COS_SECRET in namespace $IBMCLOUD_IKS_CLUSTER_NAMESPACE"
  kubectl create secret --namespace "${IBMCLOUD_IKS_CLUSTER_NAMESPACE}" generic $COS_SECRET \
    --from-literal=API_KEY="${COS_API_KEY}" \
    --from-literal=SERVICE_INSTANCE_ID="${COS_SERVICE_INSTANCE_ID}" \
    --from-literal=ENDPOINT_URL="${COS_ENDPOINT_URL}" \
    --from-literal=LOCATION="${COS_LOCATION}" \
    --from-literal=ACCOUNTS_BUCKET="${COS_ACCOUNTS_BUCKET}" \
    --from-literal=USERS_BUCKET="${COS_USERS_BUCKET}"
fi

export NS=${IBMCLOUD_IKS_CLUSTER_NAMESPACE}
mss="account-command-ms account-query-ms"
for ms in $mss; do
  export IMG=$(load_artifact $ms name |  awk -F: '{print $1}')
  export TAG=$(load_artifact $ms name |  awk -F: '{print $2}')
  cd $ms 
  make deploy
  cd ..
done

# Deploy the akme-ui using the commons deployment script for k8s application
# as this script expect a single deployment.yaml file - combine all the k8s resources definition
# in a single file
export DEPLOYMENT_FILE=akmebank-ui-global-deployment.yaml
for f in akmebank-ui/k8s/*.yaml; do
 cat $f >> $DEPLOYMENT_FILE
 echo "" >> $DEPLOYMENT_FILE
 echo "---" >> $DEPLOYMENT_FILE
done

# Set environment variables context for the deployment script
IMAGE_RESOURCE_URL=$(load_artifact akmebank-ui name)
IMAGE_URL=$(echo $IMAGE_RESOURCE_URL |  awk -F: '{print $1}')
# Image name is remaining part after the repository and namespace and can contains /
export IMAGE_NAME=$(echo $IMAGE_URL |  awk -F/ '{a=match($0, $3); print substr($0,a)}')
export IMAGE_TAG=$(echo $IMAGE_RESOURCE_URL |  awk -F: '{print $2}')
export REGISTRY_URL=$(echo $IMAGE_RESOURCE_URL |  awk -F/ '{print $1}')
export REGISTRY_NAMESPACE=$(echo $IMAGE_RESOURCE_URL |  awk -F/ '{print $2}')
export PIPELINE_BLUEMIX_API_KEY=$IBMCLOUD_API_KEY
export PIPELINE_TOOLCHAIN_ID=$IBMCLOUD_TOOLCHAIN_ID
export PIPELINE_KUBERNETES_CLUSTER_NAME="${IBMCLOUD_IKS_CLUSTER_NAME}"
export CLUSTER_NAMESPACE="${IBMCLOUD_IKS_CLUSTER_NAMESPACE}"
# pipeline build number is the doi build record id (if any)
export SOURCE_BUILD_NUMBER=$BUILD_NUMBER
# For doi plugin invocation if needed
export TOOLCHAIN_ID=$IBMCLOUD_TOOLCHAIN_ID
touch build.properties

source <(curl -sSL "https://us-south.git.cloud.ibm.com/open-toolchain/commons/-/raw/main/scripts/check_and_deploy_kubectl.sh")

set_env APP_URL "${APP_URL}"
