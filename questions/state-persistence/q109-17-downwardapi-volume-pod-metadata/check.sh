#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q109-17-downwardapi-volume-pod-metadata${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'self-aware' exists in $QUESTION_ID" \
  resource_exists pod self-aware -n "$QUESTION_ID"

check_criterion "Pod 'self-aware' has label app=self-aware" \
  [ "$(kget pod self-aware '{.metadata.labels.app}' -n "$QUESTION_ID")" = "self-aware" ]

check_criterion "Pod 'self-aware' has label tier=frontend" \
  [ "$(kget pod self-aware '{.metadata.labels.tier}' -n "$QUESTION_ID")" = "frontend" ]

check_criterion "Pod 'self-aware' has a downwardAPI volume named 'podinfo'" \
  [ "$(kget pod self-aware '{.spec.volumes[?(@.name=="podinfo")].downwardAPI}' -n "$QUESTION_ID" | wc -c)" -gt 0 ]

check_criterion "Container mounts 'podinfo' at /etc/podinfo" \
  [ "$(kget pod self-aware '{.spec.containers[0].volumeMounts[?(@.name=="podinfo")].mountPath}' -n "$QUESTION_ID")" = "/etc/podinfo" ]

kubectl wait --for=condition=Ready pod/self-aware -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1

check_criterion "File /etc/podinfo/podname contains 'self-aware'" \
  [ "$(kubectl exec -n "$QUESTION_ID" self-aware -- cat /etc/podinfo/podname 2>/dev/null)" = "self-aware" ]

check_criterion "File /etc/podinfo/labels contains tier=\"frontend\"" \
  bash -c "kubectl exec -n '$QUESTION_ID' self-aware -- cat /etc/podinfo/labels 2>/dev/null | grep -q 'tier=\"frontend\"'"

print_score
