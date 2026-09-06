#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-25-ambassador-wrong-port-two-services${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# The two backend Services/Deployments are always healthy, the pod's
# container names/count, client's image, and client's fixed localhost:9090
# target are all already correct immediately after setup.sh (the candidate
# only needs to fix the proxy's backend target) - so none of those can be
# their own criterion, or this scores before any real fix lands. Bundle
# everything into ONE criterion so nothing scores until the proxy actually
# routes to catalog-primary.
ambassador_fixed() {
  local names client_image client_cmd i phase ready_flags ready_count response_body proxy_spec

  names="$(kubectl get pod catalog-gateway -n "$QUESTION_ID" -o jsonpath='{.spec.containers[*].name}' 2>/dev/null)"
  [ "$names" = "client proxy" ] || return 1

  client_image="$(kget pod catalog-gateway '{.spec.containers[?(@.name=="client")].image}' -n "$QUESTION_ID" 2>/dev/null)"
  echo "$client_image" | grep -q busybox || return 1

  client_cmd="$(kget pod catalog-gateway '{.spec.containers[?(@.name=="client")]}' -n "$QUESTION_ID" 2>/dev/null)"
  echo "$client_cmd" | grep -q 'localhost:9090' || return 1

  # Wait for the pod to actually be Running with both containers ready
  # before exec'ing into it - a freshly recreated pod needs a moment.
  for ((i = 0; i < 24; i++)); do
    phase="$(kget pod catalog-gateway '{.status.phase}' -n "$QUESTION_ID" 2>/dev/null)"
    ready_flags="$(kget pod catalog-gateway '{.status.containerStatuses[*].ready}' -n "$QUESTION_ID" 2>/dev/null)"
    ready_count="$(echo "$ready_flags" | tr ' ' '\n' | grep -c '^true$' 2>/dev/null || true)"
    if [ "$phase" = "Running" ] && [ "$ready_count" = "2" ]; then
      break
    fi
    sleep 5
  done
  [ "$phase" = "Running" ] && [ "$ready_count" = "2" ] || return 1

  proxy_spec="$(kget pod catalog-gateway '{.spec.containers[?(@.name=="proxy")]}' -n "$QUESTION_ID" 2>/dev/null)"
  echo "$proxy_spec" | grep -q 'catalog-primary' || return 1
  echo "$proxy_spec" | grep -q 'catalog-standby' && return 1

  # The proxy container (alpine) installs socat via apk on startup, which
  # can still be finishing a moment after the container is marked Ready -
  # retry the actual traffic check instead of a single point-in-time exec.
  for ((i = 0; i < 12; i++)); do
    response_body="$(kubectl exec -n "$QUESTION_ID" catalog-gateway -c client -- \
      wget -q -T 5 -O - http://localhost:9090 2>/dev/null)"
    [ "$response_body" = "PRIMARY" ] && return 0
    sleep 5
  done
  return 1
}

check_criterion "Pod 'catalog-gateway' has client+proxy containers, client unchanged, and curl to localhost:9090 returns 'PRIMARY' via a proxy now targeting catalog-primary" \
  ambassador_fixed

print_score
