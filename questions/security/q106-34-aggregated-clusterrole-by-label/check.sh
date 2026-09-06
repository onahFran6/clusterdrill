#!/usr/bin/env bash
# Grades ONLY live cluster state - never a client-supplied "done" flag
#. No `set -e`: check_criterion returning non-zero
# on a FAIL is normal, not a script error.
set -uo pipefail

QUESTION_ID="q106-34-aggregated-clusterrole-by-label${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

AGGREGATE_ROLE="q106-34-monitoring-aggregate"
BINDING="q106-34-monitoring-aggregate-binding"
CONTRIB_ROLE="q106-34-pod-reader"
SA_NAME="metrics-reader"
SELECTOR_KEY='rbac\.example\.com/aggregate-to-q106-34-monitoring'

check_criterion "ClusterRole '$CONTRIB_ROLE' exists" \
  resource_exists clusterrole "$CONTRIB_ROLE"

check_criterion "ClusterRole '$CONTRIB_ROLE' carries the aggregation-selector label rbac.example.com/aggregate-to-q106-34-monitoring=true" \
  [ "$(kget clusterrole "$CONTRIB_ROLE" "{.metadata.labels.${SELECTOR_KEY}}")" = "true" ]

check_criterion "ClusterRole '$CONTRIB_ROLE' targets resource 'pods' in the core API group" \
  [ "$(kget clusterrole "$CONTRIB_ROLE" '{.rules[0].resources[0]}')" = "pods" ]

CONTRIB_VERBS="$(kget clusterrole "$CONTRIB_ROLE" '{.rules[0].verbs}')"

check_criterion "ClusterRole '$CONTRIB_ROLE' grants verb 'get' on pods" \
  bash -c "[[ '$CONTRIB_VERBS' == *get* ]]"

check_criterion "ClusterRole '$CONTRIB_ROLE' grants verb 'list' on pods" \
  bash -c "[[ '$CONTRIB_VERBS' == *list* ]]"

check_criterion "ClusterRole '$CONTRIB_ROLE' carries the clusterdrill-question label" \
  [ "$(kget clusterrole "$CONTRIB_ROLE" '{.metadata.labels.clusterdrill-question}')" = "$QUESTION_ID" ]

# Note: deliberately no standalone "ClusterRoleBinding is untouched"
# criterion here - setup.sh already leaves $BINDING correctly wired to
# $AGGREGATE_ROLE and $SA_NAME, so that would be trivially true before the
# candidate does anything (the exact false-positive trap this bank's gate
# checks for). The binding being untouched is instead only ever exercised
# indirectly, through the auth can-i criterion below actually depending on
# it still pointing at $AGGREGATE_ROLE.

# Aggregation is asynchronous: the aggregation controller has to notice the
# newly-labeled ClusterRole and copy its rules into $AGGREGATE_ROLE.rules
# before this is true. Empirically this happens within ~1s on this
# cluster, but poll generously (up to 20s, checked every 1s) rather than
# checking once right after the candidate's `kubectl apply` - a single
# immediate check would be a false negative here, not a true failure.
wait_for_aggregated_rules() {
  local waited=0 rules
  while (( waited < 20 )); do
    rules="$(kget clusterrole "$AGGREGATE_ROLE" '{.rules[*].resources[*]}')"
    if [[ "$rules" == *pods* ]]; then
      return 0
    fi
    sleep 1
    waited=$((waited + 1))
  done
  return 1
}

check_criterion "ClusterRole '$AGGREGATE_ROLE'.rules picks up the 'pods' rule via aggregation (polled up to 20s)" \
  wait_for_aggregated_rules

# End-to-end confirmation: the already-bound ServiceAccount actually gained
# the permission, without the candidate ever touching the binding or the
# aggregate role directly. Poll for the same asynchronous-propagation
# reason as above.
wait_for_permission() {
  local waited=0
  while (( waited < 20 )); do
    if kubectl auth can-i get pods --as="system:serviceaccount:${QUESTION_ID}:${SA_NAME}" -A 2>/dev/null | grep -q '^yes'; then
      return 0
    fi
    sleep 1
    waited=$((waited + 1))
  done
  return 1
}

check_criterion "kubectl auth can-i confirms metrics-reader can 'get pods' cluster-wide via the aggregated role (polled up to 20s)" \
  wait_for_permission

print_score
