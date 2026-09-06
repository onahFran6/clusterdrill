#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-18-secret-volume-default-mode${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'deploy-agent' mounts a volume backed by Secret ssh-key" \
  bash -c "kubectl get pod deploy-agent -n '$QUESTION_ID' -o json 2>/dev/null | grep -q '\"ssh-key\"'"

check_criterion "That volume's defaultMode is 0400 (256 decimal)" \
  [ "$(kget pod deploy-agent '{.spec.volumes[0].secret.defaultMode}' -n "$QUESTION_ID")" = "256" ]

check_criterion "That volume is mounted at /etc/ssh-key" \
  [ "$(kget pod deploy-agent '{.spec.containers[0].volumeMounts[0].mountPath}' -n "$QUESTION_ID")" = "/etc/ssh-key" ]

check_criterion "The mounted file's actual permission bits are 400 inside the container" \
  bash -c "[ \"\$(kubectl exec -n '$QUESTION_ID' deploy-agent -- stat -L -c '%a' /etc/ssh-key/id_rsa 2>/dev/null)\" = '400' ]"

print_score
