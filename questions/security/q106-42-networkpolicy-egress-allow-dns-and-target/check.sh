#!/usr/bin/env bash
# NetworkPolicy enforcement is not verified live here: only the policy's
# spec is checked, not actual traffic (matches this repo's other
# NetworkPolicy questions, e.g. q106-18, q106-27). Walked with plain
# jsonpath/grep (no python3/jq dependency), same pattern as q106-27.
set -uo pipefail

QUESTION_ID="q106-42-networkpolicy-egress-allow-dns-and-target${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'report-generator-egress' exists, selects app=report-generator, and includes Egress in policyTypes" \
  bash -c "
    kubectl get networkpolicy report-generator-egress -n '$QUESTION_ID' >/dev/null 2>&1 || exit 1
    [ \"\$(kubectl get networkpolicy report-generator-egress -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.app}')\" = 'report-generator' ] || exit 1
    kubectl get networkpolicy report-generator-egress -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes[*]}' | grep -qw Egress
  "

check_criterion "An egress rule allows UDP port 53 (DNS)" \
  bash -c '
    ns="'"$QUESTION_ID"'"
    np=report-generator-egress
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

check_criterion "An egress rule allows TCP port 80 to pods labeled app=data-store" \
  bash -c '
    ns="'"$QUESTION_ID"'"
    np=report-generator-egress
    nrules=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{range .spec.egress[*]}x{end}" 2>/dev/null | grep -o x | wc -l)
    i=0
    while [ "$i" -lt "$nrules" ]; do
      peers=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{.spec.egress[$i].to[*].podSelector.matchLabels.app}" 2>/dev/null)
      ports=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{.spec.egress[$i].ports[*].port}" 2>/dev/null)
      protos=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{.spec.egress[$i].ports[*].protocol}" 2>/dev/null)
      if echo "$peers" | grep -qw data-store && echo "$ports" | grep -qw 80 && echo "$protos" | grep -qw TCP; then
        exit 0
      fi
      i=$((i + 1))
    done
    exit 1
  '

print_score
