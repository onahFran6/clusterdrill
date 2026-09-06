#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q104-11-blue-green-service-switch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'web-svc' selector targets app=web, version=green" \
  bash -c '
    app="$(kubectl get service web-svc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.app}" 2>/dev/null)"
    version="$(kubectl get service web-svc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.version}" 2>/dev/null)"
    [ "$app" = "web" ] && [ "$version" = "green" ]
  '

check_criterion "Service 'web-svc' endpoints resolve only to green pods" \
  bash -c '
    ep_ips="$(kubectl get endpoints web-svc -n "'"$QUESTION_ID"'" -o jsonpath="{range .subsets[*].addresses[*]}{.ip}{\"\n\"}{end}" 2>/dev/null | sort)"
    green_ips="$(kubectl get pods -n "'"$QUESTION_ID"'" -l version=green -o jsonpath="{range .items[*]}{.status.podIP}{\"\n\"}{end}" 2>/dev/null | sort)"
    [ -n "$ep_ips" ] && [ -n "$green_ips" ] && [ "$ep_ips" = "$green_ips" ]
  '

check_criterion "Both Deployments (blue and green) are still intact and unmodified" \
  bash -c '
    blue_r="$(kubectl get deployment web-blue -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    blue_i="$(kubectl get deployment web-blue -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    green_r="$(kubectl get deployment web-green -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    green_i="$(kubectl get deployment web-green -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    version="$(kubectl get service web-svc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.version}" 2>/dev/null)"
    [ "$blue_r" = "3" ] && [ "$blue_i" = "nginx:1.24-alpine" ] && \
    [ "$green_r" = "3" ] && [ "$green_i" = "nginx:1.25-alpine" ] && \
    [ "$version" = "green" ]
  '

print_score
