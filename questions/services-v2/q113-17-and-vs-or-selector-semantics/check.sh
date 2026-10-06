#!/usr/bin/env bash
# Spec-only checks, same rationale as every other NetworkPolicy question in
# this bank: this cluster's default CNI does not enforce NetworkPolicy, so
# only the object's spec is asserted.
set -uo pipefail

QUESTION_ID="q113-17-and-vs-or-selector-semantics${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'allow-scrapers' has exactly one 'from' entry" \
  bash -c "kubectl get networkpolicy allow-scrapers -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get networkpolicy allow-scrapers -n '$QUESTION_ID' -o jsonpath='{range .spec.ingress[0].from[*]}x{end}')\" = 'x' ]"

check_criterion "that one 'from' entry AND-combines namespaceSelector team=monitoring with podSelector role=scraper" \
  bash -c "[ \"\$(kubectl get networkpolicy allow-scrapers -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].from[0].namespaceSelector.matchLabels.team}')\" = 'monitoring' ] && \
    [ \"\$(kubectl get networkpolicy allow-scrapers -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].from[0].podSelector.matchLabels.role}')\" = 'scraper' ]"

check_criterion "policy's own podSelector/policyTypes unchanged AND the fix above is in place" \
  bash -c "[ \"\$(kubectl get networkpolicy allow-scrapers -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.app}')\" = 'api' ] && \
    [ \"\$(kubectl get networkpolicy allow-scrapers -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}')\" = '[\"Ingress\"]' ] && \
    [ \"\$(kubectl get networkpolicy allow-scrapers -n '$QUESTION_ID' -o jsonpath='{range .spec.ingress[0].from[*]}x{end}')\" = 'x' ]"

print_score
