#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q101-25-rightsize-deployment-via-set-resources${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# millicpu <cpu-string> -> integer millicores (e.g. "100m" -> 100, "1" -> 1000)
millicpu() {
  local v="$1"
  if [[ -z "$v" ]]; then
    echo 0
  elif [[ "$v" == *m ]]; then
    echo "${v%m}"
  else
    echo $((v * 1000))
  fi
}

# mebibytes <memory-string> -> integer Mi (supports Mi/Gi/Ki suffixes; a bare
# number is treated as 0 since none of this question's values use bytes).
mebibytes() {
  local v="$1"
  if [[ -z "$v" ]]; then
    echo 0
  elif [[ "$v" == *Gi ]]; then
    echo $(( ${v%Gi} * 1024 ))
  elif [[ "$v" == *Mi ]]; then
    echo "${v%Mi}"
  elif [[ "$v" == *Ki ]]; then
    echo $(( ${v%Ki} / 1024 ))
  else
    echo 0
  fi
}

# deployment_available_and_sized
# setup.sh leaves lean-api at zero available/ready replicas (every pod
# template is rejected by the namespace's LimitRange minimum), so this is
# false until the candidate raises the container's requests to satisfy that
# floor - bundling "available=2" together with the requests actually
# satisfying the LimitRange minimum means nothing here can score before the
# real fix (kubectl set resources) lands. Defined as a function (not inline
# bash -c) so kget/millicpu/mebibytes stay visible without needing exports.
deployment_available_and_sized() {
  local available req_cpu req_mem
  available="$(kget deployment lean-api '{.status.availableReplicas}' -n "$QUESTION_ID")"
  req_cpu="$(kget deployment lean-api '{.spec.template.spec.containers[0].resources.requests.cpu}' -n "$QUESTION_ID")"
  req_mem="$(kget deployment lean-api '{.spec.template.spec.containers[0].resources.requests.memory}' -n "$QUESTION_ID")"
  [ "$available" = "2" ] || return 1
  [ "$(millicpu "$req_cpu")" -ge 100 ] || return 1
  [ "$(mebibytes "$req_mem")" -ge 64 ] || return 1
}
check_criterion "Deployment 'lean-api' has 2 available replicas with requests >= LimitRange minimum (cpu>=100m, memory>=64Mi)" \
  deployment_available_and_sized

# setup.sh already gives the container non-empty limits and the correct
# image/replica count, so neither half is a real signal on its own - bundle
# both with "available=2" (false until the candidate's fix lands) so this
# can't score in the unsolved state.
deployment_has_limits_and_available() {
  local lim_cpu lim_mem available
  lim_cpu="$(kget deployment lean-api '{.spec.template.spec.containers[0].resources.limits.cpu}' -n "$QUESTION_ID")"
  lim_mem="$(kget deployment lean-api '{.spec.template.spec.containers[0].resources.limits.memory}' -n "$QUESTION_ID")"
  available="$(kget deployment lean-api '{.status.availableReplicas}' -n "$QUESTION_ID")"
  [ -n "$lim_cpu" ] && [ -n "$lim_mem" ] && [ "$available" = "2" ]
}
check_criterion "Deployment 'lean-api' container has limits set and 2 replicas are available" \
  deployment_has_limits_and_available

deployment_unchanged_identity_and_available() {
  local available
  available="$(kget deployment lean-api '{.status.availableReplicas}' -n "$QUESTION_ID")"
  [ "$(kget deployment lean-api '{.spec.replicas}' -n "$QUESTION_ID")" = "2" ] &&
    [ "$(kget deployment lean-api '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.25-alpine" ] &&
    [ "$available" = "2" ]
}
check_criterion "Deployment 'lean-api' still runs image nginx:1.25-alpine with 2 desired replicas, all available" \
  deployment_unchanged_identity_and_available

# The LimitRange itself is already correct right after setup.sh (the
# candidate isn't supposed to touch it), so bundle it with "available=2"
# (false until the real fix lands) rather than checking it alone.
limitrange_untouched_and_available() {
  local available
  available="$(kget deployment lean-api '{.status.availableReplicas}' -n "$QUESTION_ID")"
  [ "$(kget limitrange min-container-requests '{.spec.limits[0].min.cpu}' -n "$QUESTION_ID")" = "100m" ] &&
    [ "$(kget limitrange min-container-requests '{.spec.limits[0].min.memory}' -n "$QUESTION_ID")" = "64Mi" ] &&
    [ "$available" = "2" ]
}
check_criterion "LimitRange 'min-container-requests' untouched (min cpu=100m, memory=64Mi) and 2 replicas available" \
  limitrange_untouched_and_available

print_score
