#!/usr/bin/env bash
# NetworkPolicy enforcement is not verified live here: only the policy's
# spec is checked, not actual traffic (matches this repo's other
# NetworkPolicy questions). Walked with plain jsonpath/grep.
set -uo pipefail

QUESTION_ID="q106-50-networkpolicy-namespaceselector-and-podselector-and${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'secrets-vault-allow' exists, selects app=secrets-vault, and includes Ingress in policyTypes" \
  bash -c "
    kubectl get networkpolicy secrets-vault-allow -n '$QUESTION_ID' >/dev/null 2>&1 || exit 1
    [ \"\$(kubectl get networkpolicy secrets-vault-allow -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.app}')\" = 'secrets-vault' ] || exit 1
    kubectl get networkpolicy secrets-vault-allow -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes[*]}' | grep -qw Ingress
  "

# The whole point: namespaceSelector AND podSelector must be in the SAME
# 'from' list entry (a logical AND - only pods matching both), not two
# separate entries (which K8s treats as an OR of either match). Walk each
# ingress rule's 'from' entries by index and require both selectors on the
# very same one.
check_criterion "A single 'from' peer combines namespaceSelector team=platform AND podSelector role=trusted-caller (logical AND, not two separate peers)" \
  bash -c '
    ns="'"$QUESTION_ID"'"
    np=secrets-vault-allow
    nrules=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{range .spec.ingress[*]}x{end}" 2>/dev/null | grep -o x | wc -l)
    i=0
    while [ "$i" -lt "$nrules" ]; do
      npeers=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{range .spec.ingress[$i].from[*]}x{end}" 2>/dev/null | grep -o x | wc -l)
      j=0
      while [ "$j" -lt "$npeers" ]; do
        nsteam=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{.spec.ingress[$i].from[$j].namespaceSelector.matchLabels.team}" 2>/dev/null)
        podrole=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{.spec.ingress[$i].from[$j].podSelector.matchLabels.role}" 2>/dev/null)
        if [ "$nsteam" = "platform" ] && [ "$podrole" = "trusted-caller" ]; then
          exit 0
        fi
        j=$((j + 1))
      done
      i=$((i + 1))
    done
    exit 1
  '

print_score
