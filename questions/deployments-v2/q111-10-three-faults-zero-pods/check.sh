#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q111-10-three-faults-zero-pods${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ServiceAccount 'reporter-sa' exists" \
  resource_exists serviceaccount reporter-sa -n "$QUESTION_ID"

check_criterion "Deployment references ConfigMap 'report-config' (no typo)" \
  [ "$(kget deployment reporter '{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}' -n "$QUESTION_ID")" = "report-config" ]

check_criterion "TOKEN env var references the Secret's real key 'token'" \
  bash -c '
    key="$(kubectl get deployment reporter -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].env[?(@.name==\"TOKEN\")].valueFrom.secretKeyRef.key}" 2>/dev/null)"
    [ "$key" = "token" ]
  '

check_criterion "Deployment 'reporter' has 2 Ready pods" \
  [ "$(kget deployment reporter '{.status.readyReplicas}' -n "$QUESTION_ID")" = "2" ]

print_score
