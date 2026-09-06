#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q106-43-podsecurity-restricted-rejects-root${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# setup.sh's own attempt to create 'audit-runner' is rejected by admission
# (the bug to diagnose), so the Pod does not exist until the candidate
# recreates it compliant with 'restricted'. Bundle existence + label +
# phase + the enforce level into one criterion so nothing here is
# trivially true right after setup.sh.
check_criterion "Pod 'audit-runner' exists, is labeled app=audit-runner, is Running, and the namespace still enforces restricted" \
  bash -c "
    kubectl get pod audit-runner -n '$QUESTION_ID' >/dev/null 2>&1 || exit 1
    [ \"\$(kubectl get pod audit-runner -n '$QUESTION_ID' -o jsonpath='{.metadata.labels.app}')\" = 'audit-runner' ] || exit 1
    [ \"\$(kubectl get pod audit-runner -n '$QUESTION_ID' -o jsonpath='{.status.phase}')\" = 'Running' ] || exit 1
    [ \"\$(kubectl get namespace '$QUESTION_ID' -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}')\" = 'restricted' ]
  "

check_criterion "Pod 'audit-runner' sets runAsNonRoot true (pod or container level)" \
  bash -c "
    [ \"\$(kubectl get pod audit-runner -n '$QUESTION_ID' -o jsonpath='{.spec.securityContext.runAsNonRoot}' 2>/dev/null)\" = 'true' ] || \
    [ \"\$(kubectl get pod audit-runner -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].securityContext.runAsNonRoot}' 2>/dev/null)\" = 'true' ]
  "

check_criterion "Pod 'audit-runner' container disallows privilege escalation" \
  [ "$(kget pod audit-runner '{.spec.containers[0].securityContext.allowPrivilegeEscalation}' -n "$QUESTION_ID")" = "false" ]

check_criterion "Pod 'audit-runner' container drops ALL capabilities" \
  bash -c "kubectl get pod audit-runner -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].securityContext.capabilities.drop[*]}' 2>/dev/null | grep -qw ALL"

check_criterion "Pod 'audit-runner' sets seccompProfile RuntimeDefault (pod or container level)" \
  bash -c "
    [ \"\$(kubectl get pod audit-runner -n '$QUESTION_ID' -o jsonpath='{.spec.securityContext.seccompProfile.type}' 2>/dev/null)\" = 'RuntimeDefault' ] || \
    [ \"\$(kubectl get pod audit-runner -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].securityContext.seccompProfile.type}' 2>/dev/null)\" = 'RuntimeDefault' ]
  "

check_criterion "Pod 'audit-runner' still uses busybox:1.36" \
  [ "$(kget pod audit-runner '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

print_score
