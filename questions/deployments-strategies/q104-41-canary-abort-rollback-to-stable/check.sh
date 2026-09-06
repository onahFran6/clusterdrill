#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-41-canary-abort-rollback-to-stable${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'search-canary' scaled to 0 replicas, image unchanged" \
  bash -c '
    replicas="$(kubectl get deployment search-canary -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    image="$(kubectl get deployment search-canary -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ "$replicas" = "0" ] && [ "$image" = "nginx:1.25-alpine" ]
  '

check_criterion "Deployment 'search-stable' scaled to 10 replicas, all ready, image unchanged" \
  bash -c '
    replicas="$(kubectl get deployment search-stable -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    ready="$(kubectl get deployment search-stable -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    image="$(kubectl get deployment search-stable -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ "$replicas" = "10" ] && [ "$ready" = "10" ] && [ "$image" = "nginx:1.24-alpine" ]
  '

check_criterion "Service 'search-svc' endpoints resolve only to stable pods (10 total)" \
  bash -c '
    ep_ips="$(kubectl get endpoints search-svc -n "'"$QUESTION_ID"'" -o jsonpath="{range .subsets[*].addresses[*]}{.ip}{\"\n\"}{end}" 2>/dev/null | sort)"
    stable_ips="$(kubectl get pods -n "'"$QUESTION_ID"'" -l track=stable -o jsonpath="{range .items[*]}{.status.podIP}{\"\n\"}{end}" 2>/dev/null | sort)"
    ep_count="$(echo "$ep_ips" | grep -c . )"
    [ -n "$ep_ips" ] && [ "$ep_ips" = "$stable_ips" ] && [ "$ep_count" = "10" ]
  '

print_score
