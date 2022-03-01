#!/usr/bin/env bash

set -euo pipefail

export TAG=${IMAGE_TAG}
mss="account-command-ms account-query-ms akmebank-ui cli"
for ms in $mss; do
  export IMG=${ICR_REGISTRY_REGION}.icr.io/${ICR_REGISTRY_NAMESPACE}/${ms}
  cd $ms
  make build
  make push
  DIGEST="$(docker inspect --format='{{index .RepoDigests 0}}' "${IMG}:${TAG}" | awk -F@ '{print $2}')"
  if which save_artifact >/dev/null; then
    save_artifact $ms type=image "name=${IMG}:${TAG}" "digest=${DIGEST}" "tags=${TAG}"
  fi
  cd ..
done
