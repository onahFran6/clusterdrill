#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-23-adapter-container-wrong-command-format${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# The seeded pod is already Running 2/2 and out.json is already being
# written to from the very first tick (with the wrong "code" key) - none of
# that changes on its own. Bundle the "pod healthy" baseline into the SAME
# criterion as the actual fix (a "status" key present, numeric, and no
# "code" key) so nothing scores until the candidate recreates the pod with
# a corrected json-adapter command. Poll since both containers only tick
# every 5s and a freshly recreated pod's emptyDir starts empty.
# Bundled: the image/volume-unchanged facts are already true immediately
# after setup.sh (the candidate hasn't touched them), so on their own they
# would score even in the unsolved state - only the out.json content
# actually changes. Require both together in ONE criterion so nothing
# scores until the real fix (the json-adapter command) lands.
out_json_correct_and_unchanged() {
  local i pod_phase ready_count latest_line producer_image json_adapter_image empty_dir
  for ((i = 0; i < 30; i++)); do
    pod_phase="$(kget pod legacy-bridge '{.status.phase}' -n "$QUESTION_ID" 2>/dev/null)"
    ready_count="$(kget pod legacy-bridge '{.status.containerStatuses[*].ready}' -n "$QUESTION_ID" 2>/dev/null | tr ' ' '\n' | grep -c '^true$')"
    if [ "$pod_phase" = "Running" ] && [ "$ready_count" = "2" ]; then
      latest_line="$(kubectl exec legacy-bridge -c json-adapter -n "$QUESTION_ID" -- sh -c 'tail -n 1 /data/out.json' 2>/dev/null)"
      producer_image="$(kget pod legacy-bridge '{.spec.containers[?(@.name=="producer")].image}' -n "$QUESTION_ID" 2>/dev/null)"
      json_adapter_image="$(kget pod legacy-bridge '{.spec.containers[?(@.name=="json-adapter")].image}' -n "$QUESTION_ID" 2>/dev/null)"
      empty_dir="$(kget pod legacy-bridge '{.spec.volumes[?(@.name=="shared-data")].emptyDir}' -n "$QUESTION_ID" 2>/dev/null)"
      if [ -n "$latest_line" ] \
        && echo "$latest_line" | grep -Eq '"user"[[:space:]]*:[[:space:]]*"[^"]+"' \
        && echo "$latest_line" | grep -Eq '"status"[[:space:]]*:[[:space:]]*[0-9]+' \
        && echo "$latest_line" | grep -Eq '"path"[[:space:]]*:[[:space:]]*"[^"]+"' \
        && ! echo "$latest_line" | grep -q '"code"' \
        && [ "$producer_image" = "busybox:1.36" ] \
        && [ "$json_adapter_image" = "busybox:1.36" ] \
        && [ "$empty_dir" = "{}" ]; then
        return 0
      fi
    fi
    sleep 2
  done
  return 1
}
check_criterion "Pod Running 2/2, out.json has 'user'/'status'(numeric)/'path' with no 'code', and producer/volume unchanged" \
  out_json_correct_and_unchanged

print_score
