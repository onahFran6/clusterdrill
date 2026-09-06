#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-24-immutable-selector-rejected${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled into one criterion (not "exists" / "selector unchanged" / "app
# label preserved" / "2 ready replicas" as separate checks) - setup.sh
# already creates a healthy 2/2-ready Deployment with the app label and an
# unchanged selector, so each of those alone would trivially pass before
# the candidate does anything. Gating everything on tier=backend actually
# being present makes this correctly score 0 pre-solve.
check_criterion "Deployment 'notify-service' has tier=backend on its pod template AND still has app=notify-service AND an unchanged selector ({app: notify-service} only) AND 2 ready replicas" \
  bash -c '
    tier="$(kubectl get deployment notify-service -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.metadata.labels.tier}" 2>/dev/null)"
    [ "$tier" = "backend" ] || exit 1
    app_label="$(kubectl get deployment notify-service -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.metadata.labels.app}" 2>/dev/null)"
    [ "$app_label" = "notify-service" ] || exit 1
    selector_json="$(kubectl get deployment notify-service -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.matchLabels}" 2>/dev/null)"
    [ "$selector_json" = "{\"app\":\"notify-service\"}" ] || exit 1
    ready="$(kubectl get deployment notify-service -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$ready" = "2" ]
  '

check_criterion "2 pods matching app=notify-service are Running with label tier=backend" \
  bash -c '
    count="$(kubectl get pods -n "'"$QUESTION_ID"'" -l app=notify-service,tier=backend --field-selector=status.phase=Running -o name 2>/dev/null | wc -l | tr -d " ")"
    [ "$count" = "2" ]
  '

print_score
