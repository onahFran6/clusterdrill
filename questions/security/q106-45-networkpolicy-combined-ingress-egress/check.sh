#!/usr/bin/env bash
# NetworkPolicy enforcement is not verified live here: only the policy's
# spec is checked, not actual traffic (matches this repo's other
# NetworkPolicy questions). Walked with plain jsonpath/grep.
set -uo pipefail

QUESTION_ID="q106-45-networkpolicy-combined-ingress-egress${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'payments-api-policy' exists, selects app=payments-api, and policyTypes includes both Ingress and Egress" \
  bash -c "
    kubectl get networkpolicy payments-api-policy -n '$QUESTION_ID' >/dev/null 2>&1 || exit 1
    [ \"\$(kubectl get networkpolicy payments-api-policy -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.app}')\" = 'payments-api' ] || exit 1
    types=\$(kubectl get networkpolicy payments-api-policy -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes[*]}')
    echo \"\$types\" | grep -qw Ingress || exit 1
    echo \"\$types\" | grep -qw Egress
  "

check_criterion "An ingress rule allows TCP port 80 from pods labeled app=api-gateway" \
  bash -c '
    ns="'"$QUESTION_ID"'"
    np=payments-api-policy
    nrules=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{range .spec.ingress[*]}x{end}" 2>/dev/null | grep -o x | wc -l)
    i=0
    while [ "$i" -lt "$nrules" ]; do
      peers=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{.spec.ingress[$i].from[*].podSelector.matchLabels.app}" 2>/dev/null)
      ports=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{.spec.ingress[$i].ports[*].port}" 2>/dev/null)
      protos=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{.spec.ingress[$i].ports[*].protocol}" 2>/dev/null)
      if echo "$peers" | grep -qw api-gateway && echo "$ports" | grep -qw 80 && echo "$protos" | grep -qw TCP; then
        exit 0
      fi
      i=$((i + 1))
    done
    exit 1
  '

check_criterion "An egress rule allows TCP port 5432 to pods labeled app=ledger-db" \
  bash -c '
    ns="'"$QUESTION_ID"'"
    np=payments-api-policy
    nrules=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{range .spec.egress[*]}x{end}" 2>/dev/null | grep -o x | wc -l)
    i=0
    while [ "$i" -lt "$nrules" ]; do
      peers=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{.spec.egress[$i].to[*].podSelector.matchLabels.app}" 2>/dev/null)
      ports=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{.spec.egress[$i].ports[*].port}" 2>/dev/null)
      protos=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{.spec.egress[$i].ports[*].protocol}" 2>/dev/null)
      if echo "$peers" | grep -qw ledger-db && echo "$ports" | grep -qw 5432 && echo "$protos" | grep -qw TCP; then
        exit 0
      fi
      i=$((i + 1))
    done
    exit 1
  '

check_criterion "An egress rule allows UDP port 53 (DNS)" \
  bash -c '
    ns="'"$QUESTION_ID"'"
    np=payments-api-policy
    nrules=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{range .spec.egress[*]}x{end}" 2>/dev/null | grep -o x | wc -l)
    i=0
    while [ "$i" -lt "$nrules" ]; do
      ports=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{.spec.egress[$i].ports[*].port}" 2>/dev/null)
      protos=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{.spec.egress[$i].ports[*].protocol}" 2>/dev/null)
      if echo "$ports" | grep -qw 53 && echo "$protos" | grep -qw UDP; then
        exit 0
      fi
      i=$((i + 1))
    done
    exit 1
  '

print_score
