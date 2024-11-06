#!/bin/bash
export HELM_EXPERIMENTAL_OCI=1
set -e

HELM_VERSION="$(helm version --template='Version: {{.Version}}' )"
HELM_VERSION=$(echo $HELM_VERSION | sed 's/[^0-9]*//g')

if [[ "$CHART_VERSION" != "" ]]; then
    CHART_VERSION="--version $CHART_VERSION"
fi

if [ $HELM_VERSION -ge 380 ]
then
    helm pull "oci://${BASE_CHART}" --untar --untardir "${TARGET_DIRECTORY}" $CHART_VERSION
    echo "✅ ${BASE_CHART} pulled successfully"
    echo "✅ ${BASE_CHART} saved to ${TARGET_DIRECTORY} successfully"
    echo "::set-output name=chart-path::${TARGET_DIRECTORY}"
else
    helm chart pull "${BASE_CHART}" 
    echo "✅ ${BASE_CHART} pulled successfully"
    helm chart export "${BASE_CHART}" --destination "${TARGET_DIRECTORY}"
    echo "✅ ${BASE_CHART} saved to ${TARGET_DIRECTORY} successfully"
    echo "::set-output name=chart-path::${TARGET_DIRECTORY}"
fi
