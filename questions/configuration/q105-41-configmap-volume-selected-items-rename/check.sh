#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-41-configmap-volume-selected-items-rename${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'site-renderer' is Running AND /etc/site/head.html has the header.html content" \
  bash -c '
    phase="$(kubectl get pod site-renderer -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$phase" = "Running" ] || exit 1
    content="$(kubectl exec -n "'"$QUESTION_ID"'" site-renderer -- cat /etc/site/head.html 2>/dev/null)"
    [ "$content" = "<h1>Header</h1>" ]
  '

check_criterion "/etc/site/foot.html has the footer.html content" \
  [ "$(kubectl exec -n "$QUESTION_ID" site-renderer -- cat /etc/site/foot.html 2>/dev/null)" = "<footer>Footer</footer>" ]

# Gated on /etc/site actually being mounted with the renamed content too -
# with no volume mounted at all (setup.sh's starting state), /etc/site
# doesn't exist, so "these names don't appear there" is vacuously true
# before the candidate does anything (false positive).
check_criterion "internal-notes.txt, header.html, and footer.html do not appear under /etc/site" \
  bash -c '
    head_content="$(kubectl exec -n "'"$QUESTION_ID"'" site-renderer -- cat /etc/site/head.html 2>/dev/null)"
    [ "$head_content" = "<h1>Header</h1>" ] || exit 1
    kubectl exec -n "'"$QUESTION_ID"'" site-renderer -- test ! -e /etc/site/internal-notes.txt || exit 1
    kubectl exec -n "'"$QUESTION_ID"'" site-renderer -- test ! -e /etc/site/header.html || exit 1
    kubectl exec -n "'"$QUESTION_ID"'" site-renderer -- test ! -e /etc/site/footer.html
  '

print_score
