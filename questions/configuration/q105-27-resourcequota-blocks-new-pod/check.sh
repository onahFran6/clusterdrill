#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-27-resourcequota-blocks-new-pod${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# 'sidecar-job' does not exist until the candidate applies the fixed
# manifest, so this alone already scores 0 pre-solve - but it's also
# bundled with 'primary' staying untouched (1/1 ready, requests unchanged)
# so a candidate can't pass by shrinking primary instead of fixing
# sidecar-job.
check_criterion "Deployment 'primary' still has 1/1 ready replicas with its original requests (cpu=400m, memory=400Mi) AND Deployment 'sidecar-job' exists with 1/1 ready replicas" \
  bash -c '
    p_ready="$(kubectl get deployment primary -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$p_ready" = "1" ] || exit 1
    p_replicas="$(kubectl get deployment primary -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    [ "$p_replicas" = "1" ] || exit 1
    p_cpu="$(kubectl get deployment primary -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].resources.requests.cpu}" 2>/dev/null)"
    [ "$p_cpu" = "400m" ] || exit 1
    p_mem="$(kubectl get deployment primary -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].resources.requests.memory}" 2>/dev/null)"
    [ "$p_mem" = "400Mi" ] || exit 1
    s_ready="$(kubectl get deployment sidecar-job -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$s_ready" = "1" ] || exit 1
    s_replicas="$(kubectl get deployment sidecar-job -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    [ "$s_replicas" = "1" ]
  '

# Each sidecar-job container's requests must fit the exact remaining
# budget (cpu<=100m, memory<=112Mi) left after primary's 400m/400Mi against
# the 500m/512Mi hard quota - checked per-container so a multi-container
# pod can't sneak past by shrinking only one container.
check_criterion "every container in Deployment 'sidecar-job' requests <= 100m cpu and <= 112Mi memory" \
  bash -c '
    cpu_list="$(kubectl get deployment sidecar-job -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[*].resources.requests.cpu}" 2>/dev/null)"
    mem_list="$(kubectl get deployment sidecar-job -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[*].resources.requests.memory}" 2>/dev/null)"
    [ -n "$cpu_list" ] || exit 1
    [ -n "$mem_list" ] || exit 1
    for cpu in $cpu_list; do
      millis="${cpu%m}"
      if [ "$millis" = "$cpu" ]; then
        # bare core value (e.g. "1") - convert to millicores
        millis=$(awk -v v="$cpu" "BEGIN { printf \"%d\", v*1000 }")
      fi
      [ "$millis" -le 100 ] || exit 1
    done
    for mem in $mem_list; do
      mebi="${mem%Mi}"
      case "$mem" in
        *Mi) : ;;
        *) exit 1 ;;
      esac
      [ "$mebi" -le 112 ] || exit 1
    done
  '

# Bundled with sidecar-job actually existing and being ready - setup.sh's
# lone 'primary' Deployment never comes close to compute-quota's hard
# limits by itself, so checking used <= hard alone would trivially pass
# before the candidate does anything.
check_criterion "Deployment 'sidecar-job' has 1/1 ready replicas AND ResourceQuota 'compute-quota' used.requests.cpu/memory do not exceed its hard limits (500m/512Mi)" \
  bash -c '
    s_ready="$(kubectl get deployment sidecar-job -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$s_ready" = "1" ] || exit 1

    used_cpu="$(kubectl get resourcequota compute-quota -n "'"$QUESTION_ID"'" -o jsonpath="{.status.used.requests\.cpu}" 2>/dev/null)"
    [ -n "$used_cpu" ] || exit 1
    cpu_millis="${used_cpu%m}"
    if [ "$cpu_millis" = "$used_cpu" ]; then
      cpu_millis=$(awk -v v="$used_cpu" "BEGIN { printf \"%d\", v*1000 }")
    fi
    [ "$cpu_millis" -le 500 ] || exit 1

    used_mem="$(kubectl get resourcequota compute-quota -n "'"$QUESTION_ID"'" -o jsonpath="{.status.used.requests\.memory}" 2>/dev/null)"
    [ -n "$used_mem" ] || exit 1
    case "$used_mem" in
      *Mi) mebi="${used_mem%Mi}" ;;
      *Gi) mebi=$(awk -v v="${used_mem%Gi}" "BEGIN { printf \"%d\", v*1024 }") ;;
      *) exit 1 ;;
    esac
    [ "$mebi" -le 512 ]
  '

print_score
