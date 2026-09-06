#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q103-36-job-podtemplate-annotation-propagation${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

EXPECTED='2026-09'

# Everything bundled into ONE criterion on purpose. setup.sh already creates
# a Job named metadata-tagger with the right image/command that completes
# successfully entirely on its own - none of that changes when the candidate
# acts. Only the build-id annotation (on both the Job's template AND the pod
# it creates) is genuinely false until the candidate deletes and recreates
# the Job with it, so gating everything on that keeps the unsolved score
# genuinely 0/1.
job_fixed_and_tagged() {
  resource_exists job metadata-tagger -n "$QUESTION_ID" || return 1

  local ann img cmd
  ann="$(kubectl get job metadata-tagger -n "$QUESTION_ID" -o jsonpath='{.spec.template.metadata.annotations.pipeline\.example\.com/build-id}' 2>/dev/null)"
  [ "$ann" = "$EXPECTED" ] || return 1

  img="$(kubectl get job metadata-tagger -n "$QUESTION_ID" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
  [ "$img" = "busybox:1.36" ] || return 1
  cmd="$(kubectl get job metadata-tagger -n "$QUESTION_ID" -o jsonpath='{.spec.template.spec.containers[0].command}' 2>/dev/null)"
  [ "$cmd" = '["echo","tagged"]' ] || return 1

  kubectl wait --for=condition=Complete job/metadata-tagger -n "$QUESTION_ID" --timeout=90s >/dev/null 2>&1 || return 1

  local pod_ann
  pod_ann="$(kubectl get pods -n "$QUESTION_ID" -l job-name=metadata-tagger \
    -o jsonpath='{.items[0].metadata.annotations.pipeline\.example\.com/build-id}' 2>/dev/null)"
  [ "$pod_ann" = "$EXPECTED" ]
}

check_criterion "Job 'metadata-tagger' was recreated with build-id annotation pipeline.example.com/build-id=2026-09 on its pod template, keeps its image/command, completed successfully, and the pod it created carries that same annotation" \
  job_fixed_and_tagged

print_score
