#!/usr/bin/env bash
# Grades ONLY live cluster state - never a client-supplied "done" flag.
# No `set -e`: check_criterion returns non-zero on a FAIL, which is a normal
# expected result per criterion, not a script error.
set -uo pipefail

QUESTION_ID="q103-31-podantiaffinity-required-running-on-two-nodes${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Everything below is bundled into ONE check_criterion on purpose, same
# reasoning as q103-26's check.sh: cache-0 being Running, and cache-1
# carrying the label/image/command it already had at setup, are all
# trivially true immediately after setup.sh. The only things that actually
# change when the candidate solves this are (a) cache-1 carrying a required
# podAntiAffinity rule and (b) cache-0/cache-1 landing on different nodes -
# bundling the trivial facts into the same criterion as those two real
# changes keeps the unsolved score genuinely 0/1 instead of accidentally
# scoring partial credit for conditions setup.sh already satisfied on its
# own (setup.sh does not guarantee co-location, so an unsolved cluster could
# even have the two pods on different nodes purely by scheduler luck - the
# missing anti-affinity rule is what actually gates this criterion).
fix_applied() {
  # cache-0 must still exist, be Running, and be untouched (same label).
  [ "$(kget pod cache-0 '{.status.phase}' -n "$QUESTION_ID")" = "Running" ] || return 1
  [ "$(kget pod cache-0 '{.metadata.labels.app}' -n "$QUESTION_ID")" = "cache-replica" ] || return 1

  # cache-1 must exist, carry the right label/image, and actually be Running.
  kubectl wait --for=condition=Ready pod/cache-1 -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1 || return 1
  [ "$(kget pod cache-1 '{.metadata.labels.app}' -n "$QUESTION_ID")" = "cache-replica" ] || return 1
  [ "$(kget pod cache-1 '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ] || return 1
  [ "$(kget pod cache-1 '{.spec.containers[0].command}' -n "$QUESTION_ID")" = '["sleep","3600"]' ] || return 1

  # cache-1 must carry a required (not merely preferred) podAntiAffinity rule
  # with the right selector/topology - this is the part that is FALSE until
  # the candidate deletes and recreates it.
  local required_topo required_label
  required_topo="$(kget pod cache-1 '{.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey}' -n "$QUESTION_ID")"
  required_label="$(kget pod cache-1 '{.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].labelSelector.matchLabels.app}' -n "$QUESTION_ID")"
  [ "$required_topo" = "kubernetes.io/hostname" ] || return 1
  [ "$required_label" = "cache-replica" ] || return 1

  # ...and the rule must actually be doing its job: cache-0 and cache-1 are
  # on different nodes. This is the part that only a real >= 1 additional
  # node in the cluster can ever make true - on a single-node cluster a
  # required rule like this leaves cache-1 permanently Pending (never
  # Running), so the kubectl wait above already fails first in that case.
  local node0 node1
  node0="$(kget pod cache-0 '{.spec.nodeName}' -n "$QUESTION_ID")"
  node1="$(kget pod cache-1 '{.spec.nodeName}' -n "$QUESTION_ID")"
  [ -n "$node0" ] || return 1
  [ -n "$node1" ] || return 1
  [ "$node0" != "$node1" ] || return 1

  return 0
}

check_criterion "cache-1 is deleted+recreated with a required podAntiAffinity rule (selector app=cache-replica, topologyKey kubernetes.io/hostname), reaches Running, and lands on a different node than cache-0, while cache-0 remains untouched and Running" \
  fix_applied

print_score
