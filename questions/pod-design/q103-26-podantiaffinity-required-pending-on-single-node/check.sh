#!/usr/bin/env bash
# Grades ONLY live cluster state - never a client-supplied "done" flag.
# No `set -e`: check_criterion returns non-zero on a FAIL, which is a normal
# expected result per criterion, not a script error.
set -uo pipefail

QUESTION_ID="q103-26-podantiaffinity-required-pending-on-single-node${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Everything below is bundled into ONE check_criterion on purpose. cache-0
# being Running, and cache-1 carrying the label/image/command it already had
# at setup, are all trivially true immediately after setup.sh - the only
# thing that actually changes when the candidate solves this is cache-1
# reaching Running with a *preferred* (not required) anti-affinity rule.
# Bundling the trivial facts into the same criterion as that real change
# keeps the unsolved score genuinely 0/1 (cache-1 is Pending pre-fix, so the
# whole conjunction fails) instead of accidentally scoring partial credit
# for conditions setup.sh already satisfied on its own.
fix_applied() {
  # cache-0 must still exist, be Running, and be untouched (same label).
  [ "$(kget pod cache-0 '{.status.phase}' -n "$QUESTION_ID")" = "Running" ] || return 1
  [ "$(kget pod cache-0 '{.metadata.labels.app}' -n "$QUESTION_ID")" = "cache-replica" ] || return 1

  # cache-1 must exist, carry the right label/image, and actually be Running -
  # this is the part that is FALSE until the candidate deletes and recreates
  # it with a schedulable rule (single-node cluster, hard rule -> permanently
  # Pending).
  kubectl wait --for=condition=Ready pod/cache-1 -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1 || return 1
  [ "$(kget pod cache-1 '{.metadata.labels.app}' -n "$QUESTION_ID")" = "cache-replica" ] || return 1
  [ "$(kget pod cache-1 '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ] || return 1
  [ "$(kget pod cache-1 '{.spec.containers[0].command}' -n "$QUESTION_ID")" = '["sleep","3600"]' ] || return 1

  # The hard requiredDuringScheduling rule must be gone entirely...
  local required
  required="$(kget pod cache-1 '{.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution}' -n "$QUESTION_ID")"
  [ -z "$required" ] || return 1

  # ...replaced by an equivalent preferred rule with the same selector/topology.
  local preferred_topo preferred_label
  preferred_topo="$(kget pod cache-1 '{.spec.affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.topologyKey}' -n "$QUESTION_ID")"
  preferred_label="$(kget pod cache-1 '{.spec.affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchLabels.app}' -n "$QUESTION_ID")"
  [ "$preferred_topo" = "kubernetes.io/hostname" ] || return 1
  [ "$preferred_label" = "cache-replica" ] || return 1

  return 0
}

check_criterion "cache-1 is deleted+recreated with a preferred (not required) podAntiAffinity rule (selector app=cache-replica, topologyKey kubernetes.io/hostname) and reaches Running, while cache-0 remains untouched and Running" \
  fix_applied

print_score
