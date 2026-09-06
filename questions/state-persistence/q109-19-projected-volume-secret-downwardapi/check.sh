#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q109-19-projected-volume-secret-downwardapi${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'combo-app' exists" \
  resource_exists pod combo-app -n "$QUESTION_ID"

check_criterion "Pod 'combo-app' uses image busybox:1.36" \
  [ "$(kget pod combo-app '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Pod 'combo-app' has a projected volume named 'combo'" \
  [ "$(kget pod combo-app '{.spec.volumes[?(@.name=="combo")].projected}' -n "$QUESTION_ID" | wc -c)" -gt 0 ]

kubectl wait --for=condition=Ready pod/combo-app -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1

check_criterion "Projected volume file /etc/combo/secret-token contains 's3cr3t'" \
  [ "$(kubectl exec -n "$QUESTION_ID" combo-app -- cat /etc/combo/secret-token 2>/dev/null)" = "s3cr3t" ]

check_criterion "Projected volume file /etc/combo/pod-name contains 'combo-app'" \
  [ "$(kubectl exec -n "$QUESTION_ID" combo-app -- cat /etc/combo/pod-name 2>/dev/null)" = "combo-app" ]

print_score
