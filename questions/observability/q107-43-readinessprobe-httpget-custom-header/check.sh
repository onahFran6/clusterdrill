#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-43-readinessprobe-httpget-custom-header${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled together - Ready=true and path/port unchanged are already true
# straight out of setup.sh regardless of the header, so checking them alone
# would be vacuously true before the candidate does anything.
check_criterion "Pod 'api-gateway' readinessProbe sends header X-Probe-Source: kubelet, path/port unchanged, and the Pod is Ready" \
  bash -c '
    hname="$(kubectl get pod api-gateway -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].readinessProbe.httpGet.httpHeaders[0].name}" 2>/dev/null)"
    hvalue="$(kubectl get pod api-gateway -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].readinessProbe.httpGet.httpHeaders[0].value}" 2>/dev/null)"
    [ "$hname" = "X-Probe-Source" ] && [ "$hvalue" = "kubelet" ] || exit 1
    path="$(kubectl get pod api-gateway -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].readinessProbe.httpGet.path}" 2>/dev/null)"
    port="$(kubectl get pod api-gateway -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].readinessProbe.httpGet.port}" 2>/dev/null)"
    [ "$path" = "/" ] && [ "$port" = "80" ] || exit 1
    ready="$(kubectl get pod api-gateway -n "'"$QUESTION_ID"'" -o jsonpath="{.status.conditions[?(@.type==\"Ready\")].status}" 2>/dev/null)"
    [ "$ready" = "True" ]
  '

print_score
