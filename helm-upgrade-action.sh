#!/bin/bash

set -eo pipefail

show_problems() {
    sleep ${PROBLEMS_TIMEOUT}
    echo "::group::Helm Status"
    helm status -n ${NAMESPACE} ${RELEASE_NAME}
    echo "::endgroup::"
    echo ""
    
    echo -e "::group::Deployment Description:"
    deploy_description="$(kubectl describe deploy -n ${NAMESPACE} ${RELEASE_NAME})"
    echo "$deploy_description"
    echo "::endgroup::"
    echo ""
    
    echo -e "::group::ReplicaSet Description:"
    replicaset_name=$(kubectl describe deployment -n ${NAMESPACE} ${RELEASE_NAME} | grep "^NewReplicaSet"| awk '{print $2}')
    replicaset_description="$(kubectl describe rs -n ${NAMESPACE} $replicaset_name)"
    echo "$replicaset_description"
    echo "::endgroup::"
    echo ""

    echo -e "::group::Pod Description:"
    pod_hash_label=$(kubectl get rs -n ${NAMESPACE} $replicaset_name -o jsonpath="{.metadata.labels.pod-template-hash}")
    pod_names=$(kubectl get pods -n ${NAMESPACE} -l pod-template-hash=$pod_hash_label --show-labels | tail -n +2 | awk '{print $1}')
    pod_descriptions="$(echo $pod_names | xargs kubectl describe pod -n ${NAMESPACE})"
    echo "$pod_descriptions"
    echo "::endgroup::"
    echo ""

    echo -e "::group::Pod Logs:"
    pod_logs="$(echo $pod_names | xargs kubectl logs -n ${NAMESPACE} || echo $pod_names | xargs kubectl logs -n ${NAMESPACE} --previous || echo "Could not access pod logs. Container may not have started.")"
    echo "$pod_logs"
    echo "::endgroup::"
    echo ""

    echo -e "⏳ Problems timeout seconds exceeded. Beginning analysis.\n"
    echo -e "ℹ️ There are a variety of reasons a deployment could fail. The following sections can be expanded above for deeper inspection:"
    echo "    Helm Status"    
    echo "    Deployment Description"
    echo "    ReplicaSet Description"
    echo "    Pod Description"
    echo "    Pod Logs"

    echo -e "\n⏳ Searching common causes for failures. Findings will be shown below. If none are shown, take a look through each of the previous sections.\n"

    full_logs=$(echo -e "$deploy_description $replicaset_description $pod_descriptions $pod_logs")
    
    if [[ "$full_logs" == *"CrashLoopBackOff"* ]]; then
        echo -e "::error ::❌ CrashLoopBackoff found. This occurs when either a pod crashes during startup, or a health check probe continually fails. Check pod logs above.\n"
    fi

    if [[ "$full_logs" == *"probe errored"* ]] || [[ "$full_logs" == *"probe failed"* ]]; then
        echo -e "::error ::❌ One or more probes (startup, liveness, readiness) has failed. Check the pod description.\n"
    fi

    if [[ "$full_logs" == *"ImagePullBackOff"* ]]; then
        echo -e "::error ::❌ ImagePullBackOff found. This occurs when the container image cannot be pulled. Check that the image exists and that the node has access to that image.\n"
    fi
    
    if [[ "$full_logs" == *"FailedScheduling"* ]]; then
        echo -e "::error ::❌ FailedScheduling found. Check the 'Events' section of the pod description.\n"
    fi

    if [[ "$full_logs" == *"FailedCreate"* ]]; then
        echo -e "::error ::❌ FailedCreate found. Check the 'Events' section of the pod description.\n"
    fi

    shopt -s nocasematch
    if [[ "$pod_logs" =~ "error" ]]; then
        echo -e "::error ::❌ Error found in pod logs. Check the pod logs.\n"
    fi
}
export HELM_EXPERIMENTAL_OCI=1

VALUES_FILE="-f "${VALUES_FILE}
VALUES_FILE=$(echo ${VALUES_FILE} | sed -r 's/[,]+/ -f /g')
echo ${VALUES_FILE}

if [[ ${PRINT_TEMPLATE} == "true" ]]; then
    helm_template_cmd="helm template ${RELEASE_NAME} ${HELM_CHART} ${ADDITIONAL_ARGS} ${VALUES_FILE} --set ${ADDITIONAL_VALUES} -n ${NAMESPACE}"
    echo $helm_template_cmd
    eval $helm_template_cmd
fi

helm_upgrade_cmd="helm upgrade --install ${RELEASE_NAME} ${HELM_CHART} ${ADDITIONAL_ARGS} ${VALUES_FILE} --set ${ADDITIONAL_VALUES} -n ${NAMESPACE}"
echo $helm_upgrade_cmd
if [[ -n ${PROBLEMS_TIMEOUT} ]]; then 
    show_problems &
    eval $helm_upgrade_cmd

    # Prevent show_problems from continuing to execute
    kill %1
else
    eval $helm_upgrade_cmd
fi

helm status "${RELEASE_NAME}" -n "${NAMESPACE}"
echo "✅ Helm upgrade complete"
