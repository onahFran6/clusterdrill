#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q111-09-pod-to-deployment-conversion${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ServiceAccount 'holy-sa' exists" \
  resource_exists serviceaccount holy-sa -n "$QUESTION_ID"

check_criterion "Deployment 'holy-api' has 3/3 ready, container 'holy-api' on busybox:1.36 with the original command and env preserved" \
  bash -c '
    name="$(kubectl get deployment holy-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].name}" 2>/dev/null)"
    image="$(kubectl get deployment holy-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    cmd="$(kubectl get deployment holy-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].command[2]}" 2>/dev/null)"
    cache="$(kubectl get deployment holy-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].env[?(@.name==\"CACHE_KEY\")].value}" 2>/dev/null)"
    ready="$(kubectl get deployment holy-api -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$name" = "holy-api" ] && [ "$image" = "busybox:1.36" ] \
      && [ "$cmd" = "while true; do date; sleep 10; done" ] \
      && [ "$cache" = "prod-cache" ] && [ "$ready" = "3" ]
  '

check_criterion "Pods run as ServiceAccount 'holy-sa'" \
  [ "$(kget deployment holy-api '{.spec.template.spec.serviceAccountName}' -n "$QUESTION_ID")" = "holy-sa" ]

check_criterion "Container is not privileged and does not allow privilege escalation" \
  bash -c '
    priv="$(kubectl get deployment holy-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].securityContext.privileged}" 2>/dev/null)"
    allow="$(kubectl get deployment holy-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}" 2>/dev/null)"
    [ "$priv" = "false" ] && [ "$allow" = "false" ]
  '

check_criterion "Original bare Pod 'holy-api' no longer exists" \
  bash -c '! kubectl get pod holy-api -n "'"$QUESTION_ID"'" >/dev/null 2>&1'

print_score
