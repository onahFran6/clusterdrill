#!/usr/bin/env bash
# Grades ONLY live cluster state.
set -uo pipefail

QUESTION_ID="q106-24-clusterrolebinding-view-group${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ClusterRoleBinding 'auditor-view-binding' exists and references roleRef name 'view'" \
  [ "$(kget clusterrolebinding auditor-view-binding '{.roleRef.name}')" = "view" ]

check_criterion "ClusterRoleBinding roleRef kind is 'ClusterRole'" \
  [ "$(kget clusterrolebinding auditor-view-binding '{.roleRef.kind}')" = "ClusterRole" ]

check_criterion "ClusterRoleBinding subject kind is 'ServiceAccount'" \
  [ "$(kget clusterrolebinding auditor-view-binding '{.subjects[0].kind}')" = "ServiceAccount" ]

check_criterion "ClusterRoleBinding subject is ServiceAccount 'auditor'" \
  [ "$(kget clusterrolebinding auditor-view-binding '{.subjects[0].name}')" = "auditor" ]

check_criterion "ClusterRoleBinding subject namespace is $QUESTION_ID" \
  [ "$(kget clusterrolebinding auditor-view-binding '{.subjects[0].namespace}')" = "$QUESTION_ID" ]

check_criterion "ClusterRoleBinding carries the clusterdrill-question label" \
  [ "$(kget clusterrolebinding auditor-view-binding '{.metadata.labels.clusterdrill-question}')" = "$QUESTION_ID" ]

check_criterion "kubectl auth can-i confirms auditor can list pods cluster-wide" \
  bash -c "kubectl auth can-i list pods --all-namespaces \
    --as=system:serviceaccount:${QUESTION_ID}:auditor | grep -q '^yes'"

print_score
