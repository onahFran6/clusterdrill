#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q106-37-clusterrolebinding-to-group${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ClusterRoleBinding 'q106-37-namespace-viewer-binding' exists, binds ClusterRole 'q106-37-namespace-viewer', and its subject is kind Group named 'platform-auditors'" \
  bash -c "
    kubectl get clusterrolebinding q106-37-namespace-viewer-binding >/dev/null 2>&1 || exit 1
    [ \"\$(kubectl get clusterrolebinding q106-37-namespace-viewer-binding -o jsonpath='{.roleRef.name}')\" = 'q106-37-namespace-viewer' ] || exit 1
    [ \"\$(kubectl get clusterrolebinding q106-37-namespace-viewer-binding -o jsonpath='{.subjects[0].kind}')\" = 'Group' ] || exit 1
    [ \"\$(kubectl get clusterrolebinding q106-37-namespace-viewer-binding -o jsonpath='{.subjects[0].name}')\" = 'platform-auditors' ]
  "

check_criterion "Group 'platform-auditors' can list namespaces cluster-wide" \
  bash -c "kubectl auth can-i list namespaces --as=someone --as-group=platform-auditors | grep -qx yes"

print_score
