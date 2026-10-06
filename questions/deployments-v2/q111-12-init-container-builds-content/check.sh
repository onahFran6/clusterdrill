#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q111-12-init-container-builds-content${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Init container 'build' uses busybox:1.36" \
  bash -c '
    name="$(kubectl get deployment docs -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.initContainers[0].name}" 2>/dev/null)"
    image="$(kubectl get deployment docs -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.initContainers[0].image}" 2>/dev/null)"
    [ "$name" = "build" ] && [ "$image" = "busybox:1.36" ]
  '

check_criterion "A pod-lifetime volume is mounted by both containers (nginx at /usr/share/nginx/html), 2/2 ready" \
  bash -c '
    nginx_vol="$(kubectl get deployment docs -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].volumeMounts[?(@.mountPath==\"/usr/share/nginx/html\")].name}" 2>/dev/null)"
    [ -z "$nginx_vol" ] && exit 1
    init_vol="$(kubectl get deployment docs -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.initContainers[0].volumeMounts[?(@.name==\"$nginx_vol\")].name}" 2>/dev/null)"
    is_emptydir="$(kubectl get deployment docs -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.volumes[?(@.name==\"$nginx_vol\")].emptyDir}" 2>/dev/null)"
    ready="$(kubectl get deployment docs -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$init_vol" = "$nginx_vol" ] && [ -n "$is_emptydir" ] && [ "$ready" = "2" ]
  '

check_criterion "nginx actually serves the init container's generated page at /" \
  bash -c '
    pod="$(newest_pod_name "'"$QUESTION_ID"'" app=docs)"
    [ -n "$pod" ] || exit 1
    page="$(kubectl exec "$pod" -n "'"$QUESTION_ID"'" -c nginx -- curl -s localhost 2>/dev/null)"
    [ "$page" = "built by init on $pod" ]
  '

print_score
