#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q104-09-replicaset-ownership-inspect${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# The "correct" ReplicaSet is whichever one the Deployment currently owns
# with spec.replicas > 0 - computed fresh, not hardcoded, since the RS name
# is randomly suffixed each run. This lookup itself is not a scored
# criterion (setup.sh already guarantees exactly one exists); only what the
# candidate did to it is graded below.
active_rs="$(kubectl get rs -n "$QUESTION_ID" -l app=sessions \
  -o jsonpath='{range .items[?(@.spec.replicas>0)]}{.metadata.name}{"\n"}{end}' 2>/dev/null | head -1)"

check_criterion "The active ReplicaSet is labeled active=true, and Deployment 'sessions' is untouched" \
  bash -c '
    replicas="$(kubectl get deployment sessions -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    image="$(kubectl get deployment sessions -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ -n "'"$active_rs"'" ] || exit 1
    label="$(kubectl get rs "'"$active_rs"'" -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.active}" 2>/dev/null)"
    [ "$label" = "true" ] && [ "$replicas" = "3" ] && [ "$image" = "nginx:1.25-alpine" ]
  '

check_criterion "No scaled-to-0 ReplicaSet was mistakenly labeled active=true" \
  bash -c '
    total_labeled="$(kubectl get rs -n "'"$QUESTION_ID"'" -l "active=true" --no-headers 2>/dev/null | wc -l | tr -d " ")"
    mislabeled="$(kubectl get rs -n "'"$QUESTION_ID"'" -l "active=true" -o jsonpath="{range .items[?(@.spec.replicas==0)]}{.metadata.name}{\"\n\"}{end}" 2>/dev/null)"
    [ "$total_labeled" != "0" ] && [ -z "$mislabeled" ]
  '

print_score
