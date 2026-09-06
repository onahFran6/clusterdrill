#!/usr/bin/env bash
# The gate every question must pass before it is "in the
# bank":
#
#   full_reset qNNN && setup.sh          # fresh, unsolved
#   check.sh  -> must score 0             # catches false positives
#   apply ANSWER.md's reference commands
#   check.sh  -> must score full marks    # catches false negatives
#   full_reset qNNN                      # catches incomplete cleanup
#   verify no objects remain matching -l clusterdrill-question=qNNN
#
# Usage:
#   lib/verify-question.sh questions/<topic>/qNNN-slug
#   lib/verify-question.sh --all

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BANK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=./grading.sh
source "$SCRIPT_DIR/grading.sh"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "verify-question.sh: kubectl not found on PATH" >&2
  exit 1
fi

if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "verify-question.sh: no reachable cluster (check KUBECONFIG / current-context)" >&2
  exit 1
fi

# Computed once - used by the leak check at the end of every question.
# Namespaced kinds are queried with -A since a leak could in principle land
# outside the question's own namespace; cluster-scoped kinds have no
# namespace to search within.
NAMESPACED_KINDS="$(kubectl api-resources --verbs=list --namespaced=true -o name 2>/dev/null | paste -sd, -)"
CLUSTER_KINDS="$(kubectl api-resources --verbs=list --namespaced=false -o name 2>/dev/null | paste -sd, -)"

# extract_score "<check.sh output>" -> prints "SCORE: p/t" (last match, in
# case setup/check scripts print other noise before their real score line)
extract_score() {
  echo "$1" | grep -oE 'SCORE: [0-9]+/[0-9]+' | tail -1
}

# apply_answer <question-dir> <question-id>
# Extracts every ```sh / ```bash fenced code block from ANSWER.md and runs
# it as a single bash script. This is the "apply ANSWER.md's reference
# commands" step - ANSWER.md's code fence IS the reference solution, not a
# separate solve.sh, so there is exactly one place to keep it correct.
apply_answer() {
  local qdir="$1" qid="$2"
  local answer_file="$qdir/ANSWER.md"
  local tmp
  tmp="$(mktemp)"
  awk '/^```(sh|bash)[[:space:]]*$/{flag=1; next} /^```[[:space:]]*$/{if(flag){flag=0; next}} flag' \
    "$answer_file" > "$tmp"

  if [[ ! -s "$tmp" ]]; then
    echo "verify-question.sh: $qid: no \`\`\`sh or \`\`\`bash code block found in ANSWER.md" >&2
    rm -f "$tmp"
    return 1
  fi

  bash "$tmp"
  local status=$?
  rm -f "$tmp"
  return $status
}

# check_no_leaked_objects <question-id>
# Searches every known kind (namespaced, cluster-scoped) for the question's
# label. Anything found means full_reset missed something - a more thorough check than "did the namespace disappear."
check_no_leaked_objects() {
  local qid="$1"
  # Match full_reset's lowercasing (lib/grading.sh) - setup.sh scripts for
  # mixed-case slugs (e.g. q107-21-preStop-...) label objects with the
  # lowercased id, so a raw-case label query here would silently miss them.
  local qid_lc="${qid,,}"
  local label="${CLUSTERDRILL_LABEL_KEY}=${qid_lc}"
  local leaked=""

  if [[ -n "$NAMESPACED_KINDS" ]]; then
    leaked+="$(kubectl get "$NAMESPACED_KINDS" -A -l "$label" --ignore-not-found -o name 2>/dev/null)"
  fi
  if [[ -n "$CLUSTER_KINDS" ]]; then
    leaked+=$'\n'"$(kubectl get "$CLUSTER_KINDS" -l "$label" --ignore-not-found -o name 2>/dev/null)"
  fi
  leaked="$(echo "$leaked" | sed '/^[[:space:]]*$/d')"

  if [[ -n "$leaked" ]]; then
    echo "verify-question.sh: $qid: leaked objects still labeled $label:" >&2
    echo "$leaked" >&2
    return 1
  fi
  return 0
}

# verify_one <question-dir>
verify_one() {
  local qdir="${1%/}"
  local qid
  qid="$(basename "$qdir")"

  if [[ ! -f "$qdir/setup.sh" || ! -f "$qdir/check.sh" || ! -f "$qdir/ANSWER.md" ]]; then
    echo "verify-question.sh: $qid: missing setup.sh, check.sh, or ANSWER.md - skipping" >&2
    return 1
  fi

  # Every one of this function's several early-`return 1` failure paths
  # below (setup.sh fails, unsolved check.sh is a false positive,
  # ANSWER.md fails to apply, solved check.sh is a false negative) used to
  # skip straight past the "full_reset (post)" step near the bottom,
  # leaking that question's namespace and any cluster-scoped objects
  # forever. A RETURN trap runs full_reset on
  # every exit from this function, failure or success, so no path out of
  # here can skip cleanup again - full_reset is already idempotent
  # (--ignore-not-found throughout, see grading.sh), so the harmless
  # redundant call this adds on the success path (which already calls
  # full_reset itself, as a first-class assertion that full_reset's own
  # behavior is correct - not merely for cleanup) costs nothing but a few
  # extra no-op kubectl calls.
  # `trap - RETURN` must be the trap body's own first command: a RETURN
  # trap isn't scoped to the function that set it - left armed, it fires
  # again on *every* subsequent function return, including this function's
  # own caller's return right after this one (verified empirically: it
  # cascaded into main()'s return, referencing this function's already-
  # gone local $qid and crashing under `set -u`). Clearing it here disarms
  # it the moment it fires, so it never fires a second time.
  trap 'trap - RETURN; echo "-- full_reset (cleanup on exit) --"; full_reset "$qid"' RETURN

  echo "=== verify-question.sh: $qid ==="

  echo "-- full_reset (pre) --"
  if ! full_reset "$qid"; then
    echo "verify-question.sh: $qid: FAIL - pre-run cleanup failed" >&2
    return 1
  fi

  echo "-- setup.sh --"
  if ! bash "$qdir/setup.sh"; then
    echo "verify-question.sh: $qid: FAIL - setup.sh exited non-zero" >&2
    return 1
  fi

  echo "-- check.sh (expect 0, unsolved) --"
  local unsolved_output unsolved_score unsolved_passed
  unsolved_output="$(bash "$qdir/check.sh" 2>&1)"
  echo "$unsolved_output"
  unsolved_score="$(extract_score "$unsolved_output")"
  if [[ -z "$unsolved_score" ]]; then
    echo "verify-question.sh: $qid: FAIL - check.sh printed no 'SCORE: p/t' line" >&2
    return 1
  fi
  unsolved_passed="${unsolved_score#SCORE: }"
  unsolved_passed="${unsolved_passed%%/*}"
  if [[ "$unsolved_passed" != "0" ]]; then
    echo "verify-question.sh: $qid: FAIL - unsolved state scored $unsolved_score, expected 0/N (false positive in check.sh)" >&2
    return 1
  fi

  echo "-- applying ANSWER.md reference solution --"
  if ! apply_answer "$qdir" "$qid"; then
    echo "verify-question.sh: $qid: FAIL - applying ANSWER.md exited non-zero" >&2
    return 1
  fi

  echo "-- check.sh (expect full marks) --"
  local solved_output solved_score solved_passed solved_total
  solved_output="$(bash "$qdir/check.sh" 2>&1)"
  echo "$solved_output"
  solved_score="$(extract_score "$solved_output")"
  if [[ -z "$solved_score" ]]; then
    echo "verify-question.sh: $qid: FAIL - check.sh printed no 'SCORE: p/t' line after applying the answer" >&2
    return 1
  fi
  solved_passed="${solved_score#SCORE: }"
  solved_passed="${solved_passed%%/*}"
  solved_total="${solved_score##*/}"
  if [[ "$solved_passed" != "$solved_total" ]]; then
    echo "verify-question.sh: $qid: FAIL - reference answer scored $solved_score, expected full marks (false negative in check.sh)" >&2
    return 1
  fi

  echo "-- full_reset (post) --"
  if ! full_reset "$qid"; then
    echo "verify-question.sh: $qid: FAIL - post-run cleanup failed" >&2
    return 1
  fi

  echo "-- verifying cleanup is complete --"
  if kubectl get namespace "${qid,,}" >/dev/null 2>&1; then
    echo "verify-question.sh: $qid: FAIL - namespace ${qid,,} still exists after full_reset" >&2
    return 1
  fi
  if ! check_no_leaked_objects "$qid"; then
    return 1
  fi

  echo "=== verify-question.sh: $qid PASSED ==="
  return 0
}

usage() {
  echo "usage: $(basename "$0") <question-dir> | --all" >&2
}

main() {
  if [[ $# -ne 1 ]]; then
    usage
    exit 1
  fi

  if [[ "$1" == "--all" ]]; then
    local status=0
    local qdir
    for qdir in "$BANK_ROOT"/questions/*/*/; do
      qdir="${qdir%/}"
      local base
      base="$(basename "$qdir")"
      [[ "$base" == "_template" ]] && continue
      [[ ! -f "$qdir/setup.sh" ]] && continue
      verify_one "$qdir" || status=1
    done
    exit $status
  else
    verify_one "$1"
  fi
}

main "$@"
