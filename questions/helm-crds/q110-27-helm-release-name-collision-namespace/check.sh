#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q110-27-helm-release-name-collision-namespace${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

HISTORY_JSON="$(helm history core -n "$QUESTION_ID" -o json 2>/dev/null)"

REV_COUNT="$(echo "$HISTORY_JSON" | grep -o '"revision":[0-9]*' | wc -l | tr -d ' ')"
REV_COUNT="${REV_COUNT:-0}"

check_criterion "Release 'core' has at least 2 revisions in its history" \
  [ "$REV_COUNT" -ge 2 ]

# helm history -o json prints a compact array with one object per revision,
# each containing "revision", "status", "chart", etc. Split into one
# object-fragment per revision on "}," boundaries so grep -A/-o scoped to
# revision 2 can't accidentally spill into a neighboring revision's fields.
REV2_OBJECT="$(echo "$HISTORY_JSON" | tr '}' '\n' | grep '"revision":2\b')"

REV2_STATUS="$(echo "$REV2_OBJECT" | grep -o '"status":"[a-z-]*"' | head -1 | sed -E 's/.*"([a-z-]+)"$/\1/')"
REV2_CHART="$(echo "$REV2_OBJECT" | grep -o '"chart":"[^"]*"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')"

check_criterion "Release 'core' revision 2 has status 'deployed'" \
  [ "$REV2_STATUS" = "deployed" ]

check_criterion "Release 'core' revision 2 used chart 'engine-2.0.0'" \
  [ "$REV2_CHART" = "engine-2.0.0" ]

# setup.sh already creates Deployment 'core-engine' via chart-v1, so "it
# exists" would be trivially true on the unsolved state - only assert the
# v2-only shape (containerPort 8443, env PROTOCOL=https), which can only
# become true once the candidate actually upgrades onto chart-v2.
check_criterion "Deployment 'core-engine' exposes containerPort 8443" \
  [ "$(kget deployment core-engine '{.spec.template.spec.containers[0].ports[?(@.containerPort==8443)].containerPort}' -n "$QUESTION_ID")" = "8443" ]

check_criterion "Deployment 'core-engine' has env PROTOCOL=https" \
  [ "$(kget deployment core-engine '{.spec.template.spec.containers[0].env[?(@.name=="PROTOCOL")].value}' -n "$QUESTION_ID")" = "https" ]

DEPLOY_COUNT="$(kubectl get deployment -n "$QUESTION_ID" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | tr ' ' '\n' | grep -c '^core-')"
DEPLOY_COUNT="${DEPLOY_COUNT:-0}"
V2_SHAPE="$(kget deployment core-engine '{.spec.template.spec.containers[0].ports[?(@.containerPort==8443)].containerPort}' -n "$QUESTION_ID")"

check_criterion "Only one Deployment matching 'core-*' exists and it is the upgraded v2 shape (no duplicate/orphaned release)" \
  bash -c "[ '$DEPLOY_COUNT' -eq 1 ] && [ '$V2_SHAPE' = '8443' ]"

print_score
