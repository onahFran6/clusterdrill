#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q112-04-replace-one-file-keep-the-rest${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'web' exists, image nginx:1.27" \
  [ "$(kget pod web '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.27" ]

check_criterion "index.html is subPath-mounted over nginx's own index.html" \
  bash -c '
    mounts="$(kubectl get pod web -n "'"$QUESTION_ID"'" -o json 2>/dev/null)"
    echo "$mounts" | jq -e "[.spec.containers[0].volumeMounts[]? | select(.mountPath==\"/usr/share/nginx/html/index.html\" and .subPath==\"index.html\")] | length == 1" >/dev/null
  '

check_criterion "health.html is subPath-mounted at .../healthz" \
  bash -c '
    mounts="$(kubectl get pod web -n "'"$QUESTION_ID"'" -o json 2>/dev/null)"
    echo "$mounts" | jq -e "[.spec.containers[0].volumeMounts[]? | select(.mountPath==\"/usr/share/nginx/html/healthz\" and .subPath==\"health.html\")] | length == 1" >/dev/null
  '

check_criterion "Pod is Running" \
  [ "$(kget pod web '{.status.phase}' -n "$QUESTION_ID")" = "Running" ]

check_criterion "curl / and /healthz return the seeded ConfigMap content" \
  bash -c '
    root="$(kubectl exec web -n "'"$QUESTION_ID"'" -- curl -s localhost/ 2>/dev/null)"
    health="$(kubectl exec web -n "'"$QUESTION_ID"'" -- curl -s localhost/healthz 2>/dev/null)"
    echo "$root" | grep -q "Ganymede" && echo "$health" | grep -q "ok"
  '

check_criterion "nginx's default 50x.html still exists in the html directory" \
  bash -c 'kubectl exec web -n "'"$QUESTION_ID"'" -- test -f /usr/share/nginx/html/50x.html 2>/dev/null'

print_score
