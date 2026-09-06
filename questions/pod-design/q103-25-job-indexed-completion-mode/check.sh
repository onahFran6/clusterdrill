#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q103-25-job-indexed-completion-mode${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# setup.sh already creates the Job with completions=3/parallelism=3 correct,
# so a bare "Job exists" (or "completions=3") check would be trivially true
# before the candidate touches anything. Fold existence into the same
# criterion as the field that actually starts wrong: completionMode.
job_configured_indexed() {
  resource_exists job indexed-writer -n "$QUESTION_ID" || return 1
  [ "$(kget job indexed-writer '{.spec.completionMode}' -n "$QUESTION_ID")" = "Indexed" ] || return 1
  [ "$(kget job indexed-writer '{.spec.completions}' -n "$QUESTION_ID")" = "3" ] || return 1
  [ "$(kget job indexed-writer '{.spec.parallelism}' -n "$QUESTION_ID")" = "3" ]
}

# Reads /data/output-0.txt, /data/output-1.txt, /data/output-2.txt from
# OUTSIDE the Job's pods via a short-lived reader pod on the same PVC (the
# Job's own pods use restartPolicy: Never and exit after writing, so they
# can't be kubectl exec'd into once done). Prints each file's content in
# order, or nothing for a missing file (cat's stderr is discarded), so a
# mismatch in which files exist shows up as a content mismatch too.
read_shared_outputs() {
  kubectl delete pod output-reader -n "$QUESTION_ID" --ignore-not-found --wait=true >/dev/null 2>&1
  kubectl run output-reader -n "$QUESTION_ID" --image=busybox:1.36 --restart=Never \
    --overrides='{
      "metadata": {"labels": {"clusterdrill-question": "'"$QUESTION_ID"'"}},
      "spec": {
        "containers": [{
          "name": "output-reader",
          "image": "busybox:1.36",
          "command": ["sh", "-c", "cat /data/output-0.txt 2>/dev/null; cat /data/output-1.txt 2>/dev/null; cat /data/output-2.txt 2>/dev/null"],
          "volumeMounts": [{"name": "shared", "mountPath": "/data"}],
          "resources": {"requests": {"cpu": "25m", "memory": "32Mi"}, "limits": {"cpu": "50m", "memory": "64Mi"}}
        }],
        "volumes": [{"name": "shared", "persistentVolumeClaim": {"claimName": "shared-output"}}]
      }
    }' >/dev/null 2>&1 || return 1
  kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/output-reader -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1 || {
    kubectl delete pod output-reader -n "$QUESTION_ID" --ignore-not-found --wait=false >/dev/null 2>&1
    return 1
  }
  kubectl logs output-reader -n "$QUESTION_ID" 2>/dev/null
  kubectl delete pod output-reader -n "$QUESTION_ID" --ignore-not-found --wait=false >/dev/null 2>&1
}

# Job reaching Complete is NOT by itself proof of a fix: in the broken
# (NonIndexed) state every pod still exits 0 - they just collide on the
# same filename - so the Job completes with succeeded=3 either way. The
# real signal is whether 3 DISTINCT, correctly-indexed files landed on the
# shared PVC, which only happens once JOB_COMPLETION_INDEX is actually
# injected (i.e. completionMode: Indexed).
job_completes_with_distinct_outputs() {
  resource_exists job indexed-writer -n "$QUESTION_ID" || return 1
  kubectl wait --for=condition=Complete job/indexed-writer -n "$QUESTION_ID" --timeout=180s >/dev/null 2>&1 || return 1
  [ "$(kget job indexed-writer '{.status.succeeded}' -n "$QUESTION_ID")" = "3" ] || return 1
  local outputs
  outputs="$(read_shared_outputs)"
  [ "$outputs" = "$(printf '0\n1\n2')" ]
}

check_criterion "Job 'indexed-writer' uses completionMode=Indexed with completions=3, parallelism=3" \
  job_configured_indexed

check_criterion "Job 'indexed-writer' completes with 3/3 succeeded and exactly output-0.txt/output-1.txt/output-2.txt (content 0/1/2) on the shared PVC" \
  job_completes_with_distinct_outputs

print_score
