#!/usr/bin/env bash
# Spec-only checks, same rationale as every other NetworkPolicy question in
# this bank: this cluster's default CNI does not enforce NetworkPolicy, so
# only the object's spec is asserted.
set -uo pipefail

QUESTION_ID="q108-50-networkpolicy-ipblock-peer-exclusivity-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

NP_NAME="partner-gateway-allow-ingress"

check_criterion "NetworkPolicy 'partner-gateway-allow-ingress' exists in $QUESTION_ID" \
  resource_exists networkpolicy "$NP_NAME" -n "$QUESTION_ID"

check_criterion "from-list entry has a podSelector-only peer for role=internal-caller (no ipBlock/namespaceSelector on it)" \
  bash -c "
    for i in 0 1 2; do
      role=\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath=\"{.spec.ingress[0].from[\$i].podSelector.matchLabels.role}\" 2>/dev/null)
      ipb=\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath=\"{.spec.ingress[0].from[\$i].ipBlock}\" 2>/dev/null)
      nss=\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath=\"{.spec.ingress[0].from[\$i].namespaceSelector}\" 2>/dev/null)
      if [ \"\$role\" = 'internal-caller' ] && [ -z \"\$ipb\" ] && [ -z \"\$nss\" ]; then exit 0; fi
    done
    exit 1
  "

check_criterion "from-list entry has an ipBlock-only peer for 203.0.113.0/24 (no podSelector/namespaceSelector on it)" \
  bash -c "
    for i in 0 1 2; do
      cidr=\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath=\"{.spec.ingress[0].from[\$i].ipBlock.cidr}\" 2>/dev/null)
      ps=\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath=\"{.spec.ingress[0].from[\$i].podSelector}\" 2>/dev/null)
      nss=\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath=\"{.spec.ingress[0].from[\$i].namespaceSelector}\" 2>/dev/null)
      if [ \"\$cidr\" = '203.0.113.0/24' ] && [ -z \"\$ps\" ] && [ -z \"\$nss\" ]; then exit 0; fi
    done
    exit 1
  "

check_criterion "from-list entry combines podSelector role=metrics-scraper AND namespaceSelector team=observability on the same entry" \
  bash -c "
    for i in 0 1 2; do
      role=\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath=\"{.spec.ingress[0].from[\$i].podSelector.matchLabels.role}\" 2>/dev/null)
      team=\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath=\"{.spec.ingress[0].from[\$i].namespaceSelector.matchLabels.team}\" 2>/dev/null)
      ipb=\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath=\"{.spec.ingress[0].from[\$i].ipBlock}\" 2>/dev/null)
      if [ \"\$role\" = 'metrics-scraper' ] && [ \"\$team\" = 'observability' ] && [ -z \"\$ipb\" ]; then exit 0; fi
    done
    exit 1
  "

check_criterion "from-list has exactly 3 entries, own podSelector/policyTypes/port unchanged" \
  bash -c "
    [ -z \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].from[3]}')\" ] && \
    [ \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.app}')\" = 'partner-gateway' ] && \
    [ \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}')\" = '[\"Ingress\"]' ] && \
    [ \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].ports[0].port}')\" = '443' ] && \
    [ \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].ports[0].protocol}')\" = 'TCP' ]
  "

print_score
