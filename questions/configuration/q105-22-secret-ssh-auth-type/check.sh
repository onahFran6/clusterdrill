#!/usr/bin/env bash
# Grades ONLY live cluster state.
# No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q105-22-secret-ssh-auth-type${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Secret 'deploy-key' exists in $QUESTION_ID" \
  resource_exists secret deploy-key -n "$QUESTION_ID"

check_criterion "Secret 'deploy-key' has type kubernetes.io/ssh-auth" \
  [ "$(kget secret deploy-key '{.type}' -n "$QUESTION_ID")" = "kubernetes.io/ssh-auth" ]

check_criterion "Secret 'deploy-key' has a non-empty 'ssh-privatekey' key" \
  [ -n "$(kget secret deploy-key '{.data.ssh-privatekey}' -n "$QUESTION_ID")" ]

check_criterion "Pod 'deploy-agent' mounts 'deploy-key' as a volume" \
  bash -c "kubectl get pod deploy-agent -n '$QUESTION_ID' -o jsonpath='{.spec.volumes[*].secret.secretName}' 2>/dev/null | grep -qw deploy-key"

check_criterion "'/etc/ssh-key/ssh-privatekey' is readable inside the container and matches the source file" \
  bash -c "diff <(kubectl exec deploy-agent -n '$QUESTION_ID' -- cat /etc/ssh-key/ssh-privatekey 2>/dev/null) '$HOME/practice-work/$QUESTION_ID/id_rsa' >/dev/null 2>&1"

print_score
