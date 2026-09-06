#!/usr/bin/env bash
# Grades ONLY live cluster state - never a client-supplied "done" flag,
# never whether Hint/Solution was opened.
set -uo pipefail

QUESTION_ID="q106-33-podsecurity-baseline-hostpath-rejected${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# setup.sh's own attempt to create 'log-relay' is rejected by admission (the
# bug to diagnose - baseline forbids hostPath volumes), so the Pod does not
# exist at all until the candidate recreates it with a compliant volume.
# Bundle existence + label + phase into one criterion so nothing here is
# trivially true right after setup.sh.
check_criterion "Pod 'log-relay' exists, is labeled app=log-relay, is Running, and the namespace still enforces baseline" \
  bash -c "kubectl get pod log-relay -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get pod log-relay -n '$QUESTION_ID' -o jsonpath='{.metadata.labels.app}' 2>/dev/null)\" = 'log-relay' ] && \
    [ \"\$(kubectl get pod log-relay -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)\" = 'Running' ] && \
    [ \"\$(kubectl get namespace '$QUESTION_ID' -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null)\" = 'baseline' ]"

check_criterion "Containers 'writer' and 'reader' are both Ready" \
  bash -c "
    writer_ready=\$(kubectl get pod log-relay -n '$QUESTION_ID' -o jsonpath='{range .status.containerStatuses[?(@.name==\"writer\")]}{.ready}{end}' 2>/dev/null)
    reader_ready=\$(kubectl get pod log-relay -n '$QUESTION_ID' -o jsonpath='{range .status.containerStatuses[?(@.name==\"reader\")]}{.ready}{end}' 2>/dev/null)
    [ \"\$writer_ready\" = 'true' ] && [ \"\$reader_ready\" = 'true' ]
  "

check_criterion "Pod 'log-relay' uses busybox:1.36 for both containers" \
  bash -c "
    writer_img=\$(kubectl get pod log-relay -n '$QUESTION_ID' -o jsonpath='{range .spec.containers[?(@.name==\"writer\")]}{.image}{end}' 2>/dev/null)
    reader_img=\$(kubectl get pod log-relay -n '$QUESTION_ID' -o jsonpath='{range .spec.containers[?(@.name==\"reader\")]}{.image}{end}' 2>/dev/null)
    [ \"\$writer_img\" = 'busybox:1.36' ] && [ \"\$reader_img\" = 'busybox:1.36' ]
  "

# The whole point of this question: the fix is a compliant volume TYPE, not
# a loosened policy. No volume in the pod spec may declare hostPath.
check_criterion "Pod 'log-relay' exists and does not use a hostPath volume" \
  bash -c "
    kubectl get pod log-relay -n '$QUESTION_ID' >/dev/null 2>&1 || exit 1
    hp=\$(kubectl get pod log-relay -n '$QUESTION_ID' -o jsonpath='{.spec.volumes[*].hostPath}' 2>/dev/null)
    [ -z \"\$hp\" ]
  "

# Functional requirement the volume exists for in the first place: writer's
# file is actually visible to reader through the shared volume.
check_criterion "Shared file '/var/log/relay/relay.log' in container 'reader' contains 'hello-from-writer'" \
  bash -c "
    content=\$(kubectl exec log-relay -c reader -n '$QUESTION_ID' -- cat /var/log/relay/relay.log 2>/dev/null)
    [ \"\$content\" = 'hello-from-writer' ]
  "

print_score
