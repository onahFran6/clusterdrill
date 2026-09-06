#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-42-blue-green-secret-config-cutover${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'billing-green' envFrom references app-config-green and is fully ready" \
  bash -c '
    secret_name="$(kubectl get deployment billing-green -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].envFrom[0].secretRef.name}" 2>/dev/null)"
    [ "$secret_name" = "app-config-green" ] || exit 1
    ready="$(kubectl get deployment billing-green -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$ready" = "3" ]
  '

check_criterion "Service 'billing-svc' selector targets app=billing, version=green" \
  bash -c '
    app="$(kubectl get service billing-svc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.app}" 2>/dev/null)"
    version="$(kubectl get service billing-svc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.version}" 2>/dev/null)"
    [ "$app" = "billing" ] && [ "$version" = "green" ]
  '

# Retries for up to ~30s, re-querying green_ips fresh every attempt (not
# just once): right after the rollout, the OLD ReplicaSet's pod can still be
# mid-Terminating - it still matches -l version=green (only envFrom
# changed, not labels) even though the endpoint controller has already and
# correctly excluded it. Comparing against a stale green_ips snapshot would
# never converge; re-querying lets it settle once that pod actually exits.
check_criterion "Service 'billing-svc' endpoints resolve only to green pods" \
  bash -c '
    for _ in $(seq 1 30); do
      ep_ips="$(kubectl get endpoints billing-svc -n "'"$QUESTION_ID"'" -o jsonpath="{range .subsets[*].addresses[*]}{.ip}{\"\n\"}{end}" 2>/dev/null | sort)"
      green_ips="$(kubectl get pods -n "'"$QUESTION_ID"'" -l version=green -o jsonpath="{range .items[*]}{.status.podIP}{\"\n\"}{end}" 2>/dev/null | sort)"
      [ -n "$ep_ips" ] && [ -n "$green_ips" ] && [ "$ep_ips" = "$green_ips" ] && exit 0
      sleep 1
    done
    exit 1
  '

# Gated on the green fix actually landing too (not just blue's own values) -
# billing-blue is untouched by this task by construction from setup.sh
# onward, so checking only its own values would be vacuously true before the
# candidate does anything (false positive).
check_criterion "Deployment 'billing-blue' untouched (still 3 replicas on app-config-blue)" \
  bash -c '
    green_secret="$(kubectl get deployment billing-green -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].envFrom[0].secretRef.name}" 2>/dev/null)"
    [ "$green_secret" = "app-config-green" ] || exit 1
    replicas="$(kubectl get deployment billing-blue -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    secret_name="$(kubectl get deployment billing-blue -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].envFrom[0].secretRef.name}" 2>/dev/null)"
    [ "$replicas" = "3" ] && [ "$secret_name" = "app-config-blue" ]
  '

print_score
