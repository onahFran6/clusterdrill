#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q106-49-clusterrole-nonresourceurl-healthz${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

SA="system:serviceaccount:$QUESTION_ID:health-prober"

# Note: bare GET /healthz is already granted to every authenticated
# identity by this cluster's built-in system:discovery ClusterRoleBinding
# (kubectl get clusterrole system:discovery), so it's true regardless of
# the candidate's own grant and can't be used to test anything - the real
# test is the /healthz/* subpaths, which system:discovery does NOT cover.
check_criterion "ServiceAccount 'health-prober' can GET /healthz subpaths (e.g. /healthz/etcd)" \
  bash -c "kubectl auth can-i get /healthz/etcd --as='$SA' | grep -qx yes"

check_criterion "ServiceAccount 'health-prober' can GET a different /healthz subpath too (e.g. /healthz/log)" \
  bash -c "kubectl auth can-i get /healthz/log --as='$SA' | grep -qx yes"

# Gated on the subpath grant too - "cannot access /metrics" is trivially
# true before any ClusterRole exists at all (RBAC denies by default), so on
# its own this would never score 0 pre-solve.
check_criterion "ServiceAccount 'health-prober' was not over-granted: cannot GET /metrics" \
  bash -c "
    kubectl auth can-i get /healthz/etcd --as='$SA' | grep -qx yes || exit 1
    kubectl auth can-i get /metrics --as='$SA' | grep -qx no
  "

print_score
