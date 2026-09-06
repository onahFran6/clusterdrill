#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q106-44-clusterrolebinding-serviceaccount-namespace-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ClusterRoleBinding 'q106-44-deployer-binding' subject namespace now matches this question's own namespace" \
  bash -c "
    kubectl get clusterrolebinding q106-44-deployer-binding >/dev/null 2>&1 || exit 1
    [ \"\$(kubectl get clusterrolebinding q106-44-deployer-binding -o jsonpath='{.subjects[0].namespace}')\" = '$QUESTION_ID' ] || exit 1
    [ \"\$(kubectl get clusterrolebinding q106-44-deployer-binding -o jsonpath='{.subjects[0].name}')\" = 'deployer' ]
  "

check_criterion "ServiceAccount 'deployer' in this namespace can now create Deployments cluster-wide" \
  bash -c "kubectl auth can-i create deployments -n '$QUESTION_ID' --as='system:serviceaccount:$QUESTION_ID:deployer' | grep -qx yes"

print_score
