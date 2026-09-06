#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-08-clusterrolebinding-bind-sa${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ClusterRoleBinding 'q106-08-fleet-inspector-binding' exists" \
  resource_exists clusterrolebinding q106-08-fleet-inspector-binding

check_criterion "ClusterRoleBinding references ClusterRole 'q106-08-namespace-viewer'" \
  [ "$(kget clusterrolebinding q106-08-fleet-inspector-binding '{.roleRef.name}')" = "q106-08-namespace-viewer" ]

check_criterion "ClusterRoleBinding roleRef kind is 'ClusterRole'" \
  [ "$(kget clusterrolebinding q106-08-fleet-inspector-binding '{.roleRef.kind}')" = "ClusterRole" ]

check_criterion "ClusterRoleBinding subject is ServiceAccount 'fleet-inspector'" \
  [ "$(kget clusterrolebinding q106-08-fleet-inspector-binding '{.subjects[0].name}')" = "fleet-inspector" ]

check_criterion "ClusterRoleBinding subject namespace is $QUESTION_ID" \
  [ "$(kget clusterrolebinding q106-08-fleet-inspector-binding '{.subjects[0].namespace}')" = "$QUESTION_ID" ]

check_criterion "ClusterRoleBinding carries the clusterdrill-question label" \
  [ "$(kget clusterrolebinding q106-08-fleet-inspector-binding '{.metadata.labels.clusterdrill-question}')" = "$QUESTION_ID" ]

check_criterion "kubectl auth can-i confirms fleet-inspector can list namespaces cluster-wide" \
  bash -c "kubectl auth can-i list namespaces \
    --as=system:serviceaccount:${QUESTION_ID}:fleet-inspector | grep -q '^yes'"

print_score
