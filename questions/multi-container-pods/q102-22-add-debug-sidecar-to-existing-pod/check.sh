#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-22-add-debug-sidecar-to-existing-pod${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Deliberately a single combined criterion: right after setup.sh the
# Deployment has exactly 1 container ("billing-api" only), so this is false
# until the candidate actually adds "net-debug" - it never scores non-zero
# on the unsolved namespace.
has_two_named_containers() {
  local names
  names="$(kget deployment billing-api '{.spec.template.spec.containers[*].name}' -n "$QUESTION_ID" | tr ' ' '\n' | sort | tr '\n' ' ')"
  names="${names% }"
  [ "$names" = "billing-api net-debug" ]
}
check_criterion "Deployment 'billing-api' pod template has exactly 2 containers named 'billing-api' and 'net-debug'" \
  has_two_named_containers

check_criterion "'net-debug' container uses image busybox:1.36" \
  [ "$(kget deployment billing-api '{.spec.template.spec.containers[?(@.name=="net-debug")].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

net_debug_command_sleeps() {
  kget deployment billing-api '{.spec.template.spec.containers[?(@.name=="net-debug")].command}' -n "$QUESTION_ID" | grep -q sleep
}
check_criterion "'net-debug' command sleeps to stay alive as a debug sidecar" \
  net_debug_command_sleeps

# Bundled with the container count/name check above being satisfied: on the
# unsolved namespace this alone (image unchanged + rollout available) is
# already true, since setup.sh leaves a healthy single-container Deployment
# - only counts as a pass once there are 2 named containers AND the
# original image/availability held steady across the edit.
billing_api_unchanged_and_available() {
  has_two_named_containers || return 1
  [ "$(kget deployment billing-api '{.spec.template.spec.containers[?(@.name=="billing-api")].image}' -n "$QUESTION_ID")" = "nginx:1.25" ] || return 1
  [ "$(kget deployment billing-api '{.status.availableReplicas}' -n "$QUESTION_ID")" = "1" ]
}
check_criterion "'billing-api' container unchanged (nginx:1.25) and rollout complete (1/1 available)" \
  billing_api_unchanged_and_available

pod_running_two_ready() {
  local count
  count="$(kubectl get pods -n "$QUESTION_ID" -l app=billing-api \
    --field-selector=status.phase=Running \
    -o jsonpath='{range .items[*]}{.status.phase}{" "}{range .status.containerStatuses[*]}{.ready}{" "}{end}{"\n"}{end}' 2>/dev/null \
    | grep -c '^Running true true $')"
  [ "$count" = "1" ]
}
check_criterion "Pod is Running with 2/2 containers ready" \
  pod_running_two_ready

print_score
