#!/bin/bash
export HELM_EXPERIMENTAL_OCI=1
set -e

mkdir -p $TARGET_DIRECTORY

if [[ "${ls $TARGET_DIRECTORY}" != 1 ]];
    echo "The target directory was not empty: $TARGET_DIRECTORY"
    exit 1
fi

helm pull "oci://${BASE_CHART}" --untar --untardir "${TARGET_DIRECTORY}" $CHART_VERSION
echo "✅ ${BASE_CHART} pulled successfully"
echo "✅ ${BASE_CHART} saved to ${TARGET_DIRECTORY} successfully"

CHART_PATH="$TARGET_DIRECTORY$(ls $TARGET_DIRECTORY)"
echo "chart-path=$CHART_PATH" >> "$GITHUB_OUTPUT"