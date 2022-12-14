#!/usr/bin/env bash

#
# prepare data for the release step. Here we upload all the metadata to the Inventory Repo.
# If you want to add any information or artifact to the inventory repo then use the "cocoa inventory add command"
#
. "${ONE_PIPELINE_PATH}/tools/get_repo_params"

APP_REPO="$(load_repo app-repo url)"
APP_REPO_ORG=${APP_REPO%/*}
APP_REPO_ORG=${APP_REPO_ORG##*/}
APP_REPO_NAME=${APP_REPO##*/}
APP_REPO_NAME=${APP_REPO_NAME%.git}

COMMIT_SHA="$(load_repo app-repo commit)"

INVENTORY_TOKEN_PATH="./inventory-token"
read -r INVENTORY_REPO_NAME INVENTORY_REPO_OWNER INVENTORY_SCM_TYPE INVENTORY_API_URL < <(get_repo_params "$(get_env INVENTORY_URL)" "$INVENTORY_TOKEN_PATH")

#
# collect common parameters into an array
#
params=(
    --repository-url="${APP_REPO}" \
    --commit-sha="${COMMIT_SHA}" \
    --version="${COMMIT_SHA}" \
    --build-number="${BUILD_NUMBER}" \
    --pipeline-run-id="${PIPELINE_RUN_ID}" \
    --org="$INVENTORY_REPO_OWNER" \
    --repo="$INVENTORY_REPO_NAME" \
    --git-provider="$INVENTORY_SCM_TYPE" \
    --git-token-path="$INVENTORY_TOKEN_PATH" \
    --git-api-url="$INVENTORY_API_URL"
)

#
# add the deployment files in each as a build artifact to the inventory
#
APP_TOKEN_PATH="./app-token"
# shellcheck disable=SC2034
read -r APP_REPO_NAME APP_REPO_OWNER APP_SCM_TYPE APP_API_URL < <(get_repo_params "$(get_env APP_REPO)" "$APP_TOKEN_PATH")
APP_ABSOLUTE_SCM_TYPE=$(get_absolute_scm_type "$(get_env APP_REPO)")

token=$(cat $APP_TOKEN_PATH)

mss="account-command-ms account-query-ms akmebank-ui"
for ms in $mss; do
  for f in "$ms"/k8s/*; do
    echo "$f"
    echo "APP_SCM_TYPE=$APP_SCM_TYPE"
    echo "APP_ABSOLUTE_SCM_TYPE=$APP_ABSOLUTE_SCM_TYPE"
    if [ "$APP_SCM_TYPE" == "gitlab" ]; then
        id=$(curl --header "PRIVATE-TOKEN: ${token}" "${APP_API_URL}/projects/${APP_REPO_ORG}%2F${APP_REPO_NAME}" | jq .id)
        file_path=$(echo "$f" | jq -rR '@uri')
        DEPLOYMENT_ARTIFACT="${APP_API_URL}/projects/${id}/repository/files/$file_path/raw?ref=${COMMIT_SHA}"
    else
        if [ "$APP_ABSOLUTE_SCM_TYPE" == "github_integrated" ]; then
            DEPLOYMENT_ARTIFACT="https://raw.github.ibm.com/${APP_REPO_ORG}/${APP_REPO_NAME}/${COMMIT_SHA}/$f"
        else
            if [ "$APP_ABSOLUTE_SCM_TYPE" == "bitbucketgit" ]; then
                DEPLOYMENT_ARTIFACT="https://bitbucket.org/${APP_REPO_ORG}/${APP_REPO_NAME}/raw/${COMMIT_SHA}/$f"
            else
                # Default to github
                DEPLOYMENT_ARTIFACT="https://raw.githubusercontent.com/${APP_REPO_ORG}/${APP_REPO_NAME}/${COMMIT_SHA}/$f"
            fi
        fi
    fi
    DEPLOYMENT_ARTIFACT_PATH="$(load_repo app-repo path)"
    DEPLOYMENT_ARTIFACT_DIGEST="$(shasum -a256 "${WORKSPACE}/${DEPLOYMENT_ARTIFACT_PATH}/$f" | awk '{print $1}')"

    cocoa inventory add \
        --artifact="${DEPLOYMENT_ARTIFACT}" \
        --type="deployment" \
        --sha256="${DEPLOYMENT_ARTIFACT_DIGEST}" \
        --signature="${DEPLOYMENT_ARTIFACT_DIGEST}" \
        --name="${APP_REPO_NAME}_${ms}_$(basename -s .yaml "$f")" \
        "${params[@]}"
  done
done

#
# add all built images as build artifacts to the inventory
#
while read -r artifact ; do
    image="$(load_artifact "${artifact}" name)"
    signature="$(load_artifact "${artifact}" signature)"
    digest="$(load_artifact "${artifact}" digest)"
    tags="$(load_artifact "${artifact}" tags)"

    APP_NAME="$(get_env app-name)"
    APP_ARTIFACTS='{ "app": "'${APP_NAME}'", "tags": "'${tags}'" }'

    cocoa inventory add \
        --artifact="${image}@${digest}" \
        --name="${APP_REPO_NAME}_${artifact}" \
        --app-artifacts="${APP_ARTIFACTS}" \
        --signature="${signature}" \
        --provenance="${image}@${digest}" \
        --sha256="${digest}" \
        --type="image" \
        "${params[@]}"
done < <(list_artifacts)
