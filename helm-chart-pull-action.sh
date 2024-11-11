#!/bin/bash
export HELM_EXPERIMENTAL_OCI=1
set -e

helm pull "oci://${BASE_CHART}" --untar --untardir "${TARGET_DIRECTORY}" -d "${CHART_DESTINATION}" $CHART_VERSION
echo "✅ ${BASE_CHART} pulled successfully"
echo "✅ ${BASE_CHART} saved to ${TARGET_DIRECTORY} successfully"