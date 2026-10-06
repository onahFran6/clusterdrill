#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q115-03-pin-by-digest${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'web' references nginx by digest, not a tag" \
  bash -c '
    img="$(kubectl get deployment web -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [[ "$img" =~ ^nginx@sha256:[0-9a-f]{64}$ ]]
  '

# Rollout after `kubectl set image` needs a moment to settle - every live
# pod's own containerStatuses[].imageID must resolve to the same digest the
# Deployment's spec now asks for, confirmed via a short retry loop rather
# than a bare single-shot check.
pods_resolve_to_spec_digest() {
  local spec_image spec_digest max_wait=60 waited=0

  spec_image="$(kubectl get deployment web -n "$QUESTION_ID" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
  spec_digest="${spec_image#*@}"
  [[ "$spec_digest" =~ ^sha256:[0-9a-f]{64}$ ]] || return 1

  while :; do
    local ready total all_match=1 pod imageid
    ready="$(kubectl get deployment web -n "$QUESTION_ID" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
    total="$(kubectl get deployment web -n "$QUESTION_ID" -o jsonpath='{.spec.replicas}' 2>/dev/null)"
    if [ "$ready" = "$total" ] && [ -n "$ready" ]; then
      for pod in $(kubectl get pods -n "$QUESTION_ID" -l app=web -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
        imageid="$(kubectl get pod "$pod" -n "$QUESTION_ID" -o jsonpath='{.status.containerStatuses[0].imageID}' 2>/dev/null)"
        case "$imageid" in
          *"$spec_digest"*) ;;
          *) all_match=0 ;;
        esac
      done
      [ "$all_match" -eq 1 ] && return 0
    fi
    if [ "$waited" -ge "$max_wait" ]; then
      return 1
    fi
    sleep 5
    waited=$((waited + 5))
  done
}

check_criterion "Every live 'web' pod's imageID resolves to the Deployment's pinned digest, 2/2 Running" \
  pods_resolve_to_spec_digest

print_score
