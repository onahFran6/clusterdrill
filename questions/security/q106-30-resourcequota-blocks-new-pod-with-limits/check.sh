#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q106-30-resourcequota-blocks-new-pod-with-limits${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# cpu_to_millicores <qty>
# Converts a CPU quantity like "100m", "0.1", "1" to an integer millicore
# count. Empty/unparseable input becomes empty (caller treats as failure).
cpu_to_millicores() {
  local qty="$1"
  if [[ -z "$qty" ]]; then
    return
  fi
  if [[ "$qty" == *m ]]; then
    echo "${qty%m}"
  else
    awk -v q="$qty" 'BEGIN { printf "%d", q * 1000 }'
  fi
}

# mem_to_mebibytes <qty>
# Converts a memory quantity like "56Mi", "256Mi", "1Gi", "200000Ki" to an
# integer count of Mi (mebibytes, 2^20 bytes). Empty/unparseable -> empty.
mem_to_mebibytes() {
  local qty="$1"
  if [[ -z "$qty" ]]; then
    return
  fi
  case "$qty" in
    *Ki) awk -v q="${qty%Ki}" 'BEGIN { printf "%.6f", q / 1024 }' ;;
    *Mi) echo "${qty%Mi}" ;;
    *Gi) awk -v q="${qty%Gi}" 'BEGIN { printf "%.6f", q * 1024 }' ;;
    *) awk -v q="$qty" 'BEGIN { printf "%.6f", q / (1024*1024) }' ;;
  esac
}

# sum_namespace_pod_requests <resource-jsonpath-field>
# Sums a given resources.requests field (cpu or memory, already normalized
# by the caller into a comparable unit) across every container of every
# Pod currently in the namespace.
sum_pod_cpu_millicores() {
  local total=0
  local vals
  vals="$(kubectl get pods -n "$QUESTION_ID" -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.resources.requests.cpu}{"\n"}{end}{end}' 2>/dev/null)"
  while IFS= read -r v; do
    [[ -z "$v" ]] && continue
    local mc
    mc="$(cpu_to_millicores "$v")"
    [[ -z "$mc" ]] && continue
    total=$((total + mc))
  done <<<"$vals"
  echo "$total"
}

sum_pod_memory_mi() {
  local total=0
  local vals
  vals="$(kubectl get pods -n "$QUESTION_ID" -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.resources.requests.memory}{"\n"}{end}{end}' 2>/dev/null)"
  while IFS= read -r v; do
    [[ -z "$v" ]] && continue
    local mi
    mi="$(mem_to_mebibytes "$v")"
    [[ -z "$mi" ]] && continue
    total="$(awk -v a="$total" -v b="$mi" 'BEGIN { printf "%.6f", a + b }')"
  done <<<"$vals"
  echo "$total"
}

# The Deployment existing with a healthy replica AND the quota still being
# exactly what setup.sh created are bundled into one criterion: right after
# setup.sh the quota is already correct but new-worker does not exist yet,
# so this criterion is false until the candidate actually creates it.
deployment_ready_and_quota_intact() {
  local ready
  ready="$(kget deployment new-worker '{.status.readyReplicas}' -n "$QUESTION_ID")"
  [[ "$ready" == "1" ]] || return 1

  local desired
  desired="$(kget deployment new-worker '{.spec.replicas}' -n "$QUESTION_ID")"
  [[ "$desired" == "1" ]] || return 1

  local qcpu qmem
  qcpu="$(kget resourcequota team-quota '{.spec.hard.requests\.cpu}' -n "$QUESTION_ID")"
  qmem="$(kget resourcequota team-quota '{.spec.hard.requests\.memory}' -n "$QUESTION_ID")"
  [[ "$qcpu" == "500m" ]] || return 1
  [[ "$qmem" == "256Mi" ]] || return 1

  return 0
}

check_criterion "Deployment 'new-worker' is 1/1 ready and 'team-quota' is unchanged" \
  deployment_ready_and_quota_intact

check_criterion "new-worker's container image is nginx:1.25-alpine" \
  [ "$(kget deployment new-worker '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.25-alpine" ]

container_request_within_limit() {
  local cpu_req mem_req cpu_mc mem_mi
  cpu_req="$(kget deployment new-worker '{.spec.template.spec.containers[0].resources.requests.cpu}' -n "$QUESTION_ID")"
  mem_req="$(kget deployment new-worker '{.spec.template.spec.containers[0].resources.requests.memory}' -n "$QUESTION_ID")"
  [[ -n "$cpu_req" ]] || return 1
  [[ -n "$mem_req" ]] || return 1

  cpu_mc="$(cpu_to_millicores "$cpu_req")"
  mem_mi="$(mem_to_mebibytes "$mem_req")"
  [[ -n "$cpu_mc" ]] || return 1
  [[ -n "$mem_mi" ]] || return 1

  awk -v c="$cpu_mc" 'BEGIN { exit !(c <= 100) }' || return 1
  awk -v m="$mem_mi" 'BEGIN { exit !(m <= 56) }' || return 1
  return 0
}

check_criterion "new-worker's container requests.cpu <= 100m and requests.memory <= 56Mi" \
  container_request_within_limit

# Bundled with new-worker actually existing and being ready: right after
# setup.sh, existing-worker alone is already within the quota, so checking
# the namespace total in isolation would be trivially true before the
# candidate does anything. Requiring new-worker to also be 1/1 ready here
# means this criterion only passes once the candidate's Deployment is both
# created AND sized to fit alongside existing-worker.
namespace_totals_within_quota_with_new_worker_ready() {
  local ready
  ready="$(kget deployment new-worker '{.status.readyReplicas}' -n "$QUESTION_ID")"
  [[ "$ready" == "1" ]] || return 1

  local total_cpu total_mem
  total_cpu="$(sum_pod_cpu_millicores)"
  total_mem="$(sum_pod_memory_mi)"
  awk -v c="$total_cpu" 'BEGIN { exit !(c <= 500) }' || return 1
  awk -v m="$total_mem" 'BEGIN { exit !(m <= 256) }' || return 1
  return 0
}

check_criterion "new-worker is ready and total namespace requests.cpu/requests.memory stay within team-quota's hard limits" \
  namespace_totals_within_quota_with_new_worker_ready

print_score
