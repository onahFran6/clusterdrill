#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-32-emptydir-shared-initcontainer-writer${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'config-fetcher' exists and is Running" \
  bash -c "[ \"\$(kubectl get pod config-fetcher -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)\" = 'Running' ]"

check_criterion "Init container 'fetch-config' succeeded" \
  [ "$(kget pod config-fetcher '{.status.initContainerStatuses[0].state.terminated.reason}' -n "$QUESTION_ID")" = "Completed" ]

check_criterion "Main container 'app' can read /work/config.txt written by the init container" \
  bash -c "[ \"\$(kubectl exec config-fetcher -n '$QUESTION_ID' -c app -- cat /work/config.txt 2>/dev/null)\" = 'ready' ]"

check_criterion "Volume 'work' is an emptyDir mounted at /work in both containers" \
  bash -c "
    [ -n \"\$(kubectl get pod config-fetcher -n '$QUESTION_ID' -o jsonpath='{.spec.volumes[?(@.name==\"work\")].emptyDir}')\" ] && \
    kubectl get pod config-fetcher -n '$QUESTION_ID' -o jsonpath='{.spec.initContainers[0].volumeMounts[?(@.name==\"work\")].mountPath}' | grep -qx '/work' && \
    kubectl get pod config-fetcher -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].volumeMounts[?(@.name==\"work\")].mountPath}' | grep -qx '/work'
  "

print_score
