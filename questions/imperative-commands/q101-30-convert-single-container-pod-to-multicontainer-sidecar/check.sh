#!/usr/bin/env bash
# Grades ONLY live cluster state - never a client-supplied "done" flag.
set -uo pipefail

QUESTION_ID="q101-30-convert-single-container-pod-to-multicontainer-sidecar${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Right after setup.sh, web-writer has exactly ONE container ('main'), so
# "exactly two containers named main and log-shipper" cannot be trivially
# true - it only passes once the candidate has recreated the Pod with the
# sidecar added. Bundle both the count and the exact names into one
# criterion so a partial/incorrect edit (e.g. renaming 'main', or adding a
# container with the wrong name) still fails.
correct_container_set() {
  local names
  names="$(kget pod web-writer '{.spec.containers[*].name}' -n "$QUESTION_ID")" || return 1
  [ "$names" = "main log-shipper" ] || [ "$names" = "log-shipper main" ]
}

check_criterion "Pod 'web-writer' has exactly two containers: 'main' and 'log-shipper'" \
  correct_container_set

# "main mounts log-vol" alone is already true right after setup.sh (it
# never changes), so bundle it with "log-shipper also mounts log-vol" in
# the SAME criterion - this only ever passes once the candidate has added
# the sidecar with its own matching mount, never on the unsolved pod.
both_containers_mount_log_vol() {
  local main_mount shipper_mount
  main_mount="$(kubectl get pod web-writer -n "$QUESTION_ID" \
    -o jsonpath='{.spec.containers[?(@.name=="main")].volumeMounts[?(@.mountPath=="/var/log/app")].name}' 2>/dev/null)"
  shipper_mount="$(kubectl get pod web-writer -n "$QUESTION_ID" \
    -o jsonpath='{.spec.containers[?(@.name=="log-shipper")].volumeMounts[?(@.mountPath=="/var/log/app")].name}' 2>/dev/null)"
  [ "$main_mount" = "log-vol" ] && [ "$shipper_mount" = "log-vol" ]
}

check_criterion "Both 'main' and 'log-shipper' mount 'log-vol' at /var/log/app" \
  both_containers_mount_log_vol

# Prove log-shipper is actually tailing main's output, not just present in
# the spec: both containers must be Ready, and log-shipper's own stdout
# (via kubectl logs) must contain a line in main's "hello from main" log
# format. This cannot pass before the candidate's fix since log-shipper
# does not exist yet at all right after setup.sh.
log_shipper_streaming_main_output() {
  local i ready
  for i in $(seq 1 20); do
    ready="$(kubectl get pod web-writer -n "$QUESTION_ID" \
      -o jsonpath='{range .status.containerStatuses[*]}{.name}={.ready}{"\n"}{end}' 2>/dev/null)"
    if echo "$ready" | grep -qx "main=true" && echo "$ready" | grep -qx "log-shipper=true"; then
      break
    fi
    sleep 3
  done
  echo "$ready" | grep -qx "main=true" || return 1
  echo "$ready" | grep -qx "log-shipper=true" || return 1

  # Give the tail a moment to catch at least one appended line.
  for i in $(seq 1 10); do
    if kubectl logs web-writer -c log-shipper -n "$QUESTION_ID" 2>/dev/null | grep -q "hello from main"; then
      return 0
    fi
    sleep 2
  done
  return 1
}

check_criterion "log-shipper's logs contain main's timestamped output lines" \
  log_shipper_streaming_main_output

print_score
