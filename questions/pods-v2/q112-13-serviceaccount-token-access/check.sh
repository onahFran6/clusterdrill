#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q112-13-serviceaccount-token-access${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ServiceAccount+Pod 'scanner' exist, token automount disabled" \
  bash -c '
    sa_exists="$(kubectl get sa scanner -n "'"$QUESTION_ID"'" >/dev/null 2>&1 && echo yes)"
    automount="$(kubectl get pod scanner -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.automountServiceAccountToken}" 2>/dev/null)"
    sa_used="$(kubectl get pod scanner -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.serviceAccountName}" 2>/dev/null)"
    [ "$sa_exists" = "yes" ] && [ "$automount" = "false" ] && [ "$sa_used" = "scanner" ]
  '

check_criterion "scanner Pod is Running with no mounted token directory" \
  bash -c '
    phase="$(kubectl get pod scanner -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$phase" = "Running" ] || exit 1
    ! kubectl exec scanner -n "'"$QUESTION_ID"'" -- ls /var/run/secrets/kubernetes.io/serviceaccount >/dev/null 2>&1
  '

check_criterion "Role grants exactly get+list on pods, bound to SA 'lister' via RoleBinding" \
  bash -c '
    verbs="$(kubectl get role -n "'"$QUESTION_ID"'" -o json 2>/dev/null | jq -r "[.items[].rules[]? | select(.resources[]? == \"pods\") | .verbs[]] | sort | join(\",\")")"
    rb="$(kubectl get rolebinding -n "'"$QUESTION_ID"'" -o json 2>/dev/null | jq -r "[.items[] | select(.subjects[]?.name == \"lister\")] | length")"
    [ "$verbs" = "get,list" ] && [ "$rb" -ge 1 ]
  '

check_criterion "Pod 'lister' (curlimages/curl) uses ServiceAccount 'lister'" \
  bash -c '
    img="$(kubectl get pod lister -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
    sa="$(kubectl get pod lister -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.serviceAccountName}" 2>/dev/null)"
    echo "$img" | grep -q "curlimages/curl" && [ "$sa" = "lister" ]
  '

check_criterion "lister can list this namespace's Pods via its own mounted token" \
  bash -c '
    kubectl exec lister -n "'"$QUESTION_ID"'" -- sh -c "
      D=/var/run/secrets/kubernetes.io/serviceaccount
      code=\$(curl -s -o /dev/null -w \"%{http_code}\" --cacert \$D/ca.crt \
        -H \"Authorization: Bearer \$(cat \$D/token)\" \
        https://kubernetes.default.svc/api/v1/namespaces/'"$QUESTION_ID"'/pods)
      [ \"\$code\" = \"200\" ]
    " 2>/dev/null
  '

print_score
