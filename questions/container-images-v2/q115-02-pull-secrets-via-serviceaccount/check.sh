#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
#
# Pod 'app' points at a fictional registry (registry.example.com) by design -
# it is never expected to reach Running. Grading stops at "did Kubernetes
# accept and correctly wire the objects."
set -uo pipefail

QUESTION_ID="q115-02-pull-secrets-via-serviceaccount${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Secret 'regcred' is a dockerconfigjson Secret for registry.example.com" \
  bash -c '
    type="$(kubectl get secret regcred -n "'"$QUESTION_ID"'" -o jsonpath="{.type}" 2>/dev/null)"
    [ "$type" = "kubernetes.io/dockerconfigjson" ] || exit 1
    kubectl get secret regcred -n "'"$QUESTION_ID"'" -o jsonpath="{.data.\.dockerconfigjson}" 2>/dev/null \
      | base64 -d 2>/dev/null | grep -q "registry.example.com"
  '

check_criterion "ServiceAccount 'builder' lists 'regcred' in imagePullSecrets" \
  bash -c '
    kubectl get sa builder -n "'"$QUESTION_ID"'" -o json 2>/dev/null \
      | jq -e "[.imagePullSecrets[]?.name] | index(\"regcred\") != null" >/dev/null
  '

check_criterion "Pod 'app' uses ServiceAccount builder and inherited regcred at creation time" \
  bash -c '
    img="$(kubectl get pod app -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
    sa="$(kubectl get pod app -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.serviceAccountName}" 2>/dev/null)"
    [ "$img" = "registry.example.com/team/app:1.0" ] && [ "$sa" = "builder" ] || exit 1
    kubectl get pod app -n "'"$QUESTION_ID"'" -o json 2>/dev/null \
      | jq -e "[.spec.imagePullSecrets[]?.name] | index(\"regcred\") != null" >/dev/null
  '

print_score
