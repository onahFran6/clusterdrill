#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-13-helm-uninstall-keep-history${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'demo-widget' no longer exists in $QUESTION_ID" \
  bash -c "! kubectl get deployment demo-widget -n '$QUESTION_ID' >/dev/null 2>&1"

# With --keep-history, 'helm status demo' still exits 0 (history is kept),
# but its status field flips from "deployed" to "uninstalled" - and with no
# history at all the command fails outright. Either way proves the release
# is no longer active.
STATUS_GONE="no"
STATUS_JSON="$(helm status demo -n "$QUESTION_ID" -o json 2>/dev/null)"
if [ -z "$STATUS_JSON" ]; then
  STATUS_GONE="yes"
elif ! echo "$STATUS_JSON" | grep -q '"status":"deployed"'; then
  STATUS_GONE="yes"
fi
check_criterion "'helm status demo' no longer reports the release as deployed" \
  [ "$STATUS_GONE" = "yes" ]

HISTORY_JSON="$(helm history demo -n "$QUESTION_ID" -o json 2>/dev/null)"

HAS_UNINSTALLED_REVISION="no"
if echo "$HISTORY_JSON" | grep -q '"uninstalled"'; then
  HAS_UNINSTALLED_REVISION="yes"
fi

# Only meaningful together with STATUS_GONE: history is trivially non-empty
# right after setup.sh installs the release (revision 1, status "deployed"),
# so history alone can't prove the candidate actually uninstalled with
# --keep-history rather than leaving the release untouched.
check_criterion "Release is uninstalled but 'helm history demo' still shows a retained 'uninstalled' revision" \
  bash -c "[ '$STATUS_GONE' = 'yes' ] && [ '$HAS_UNINSTALLED_REVISION' = 'yes' ]"

print_score
