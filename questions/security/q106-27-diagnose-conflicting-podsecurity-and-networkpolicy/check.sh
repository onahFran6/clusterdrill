#!/usr/bin/env bash
# NetworkPolicy enforcement is not verified live here: this cluster's default
# CNI does not enforce NetworkPolicy objects, only the API server accepts and
# stores them. The ingress-allow criterion below asserts the policy's *spec*
# permits role=client on port 8080 (the part a CKAD grader/exam checks too),
# not that traffic is actually blocked/allowed.
set -uo pipefail

QUESTION_ID="q106-27-diagnose-conflicting-podsecurity-and-networkpolicy${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# setup.sh's own attempt to create 'worker' is rejected by admission (the bug
# to diagnose), so the Pod does not exist until the candidate recreates it
# compliant with the namespace's 'restricted' PodSecurity label. Bundle
# existence + label + phase into one criterion so nothing here is trivially
# true right after setup.sh.
check_criterion "Pod 'worker' exists, is labeled app=worker, and is Running" \
  bash -c "[ \"\$(kubectl get pod worker -n '$QUESTION_ID' -o jsonpath='{.metadata.labels.app}' 2>/dev/null)\" = 'worker' ] && \
    [ \"\$(kubectl get pod worker -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)\" = 'Running' ]"

check_criterion "Pod 'worker' container 'worker' sets runAsNonRoot true" \
  bash -c "[ \"\$(kubectl get pod worker -n '$QUESTION_ID' -o jsonpath='{.spec.securityContext.runAsNonRoot}' 2>/dev/null)\" = 'true' ] || \
    [ \"\$(kubectl get pod worker -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].securityContext.runAsNonRoot}' 2>/dev/null)\" = 'true' ]"

check_criterion "Pod 'worker' container disallows privilege escalation" \
  [ "$(kget pod worker '{.spec.containers[0].securityContext.allowPrivilegeEscalation}' -n "$QUESTION_ID")" = "false" ]

check_criterion "Pod 'worker' container drops ALL capabilities" \
  bash -c "kubectl get pod worker -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].securityContext.capabilities.drop[*]}' 2>/dev/null | grep -qw ALL"

check_criterion "Pod 'worker' sets seccompProfile RuntimeDefault" \
  bash -c "[ \"\$(kubectl get pod worker -n '$QUESTION_ID' -o jsonpath='{.spec.securityContext.seccompProfile.type}' 2>/dev/null)\" = 'RuntimeDefault' ] || \
    [ \"\$(kubectl get pod worker -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].securityContext.seccompProfile.type}' 2>/dev/null)\" = 'RuntimeDefault' ]"

check_criterion "Pod 'worker' exists and does not request privileged:true" \
  bash -c "kubectl get pod worker -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get pod worker -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].securityContext.privileged}' 2>/dev/null)\" != 'true' ]"

check_criterion "Service 'worker-svc' has a populated endpoint (pod is selected and ready)" \
  bash -c "kubectl get endpoints worker-svc -n '$QUESTION_ID' -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null | grep -qE '.+'"

# Some NetworkPolicy in the namespace (new or edited) must select app=worker,
# allow Ingress, permit a podSelector role=client peer, and restrict to
# TCP/8080. Walked with plain jsonpath/grep (no python3 dependency): for each
# ingress rule index on each matching NetworkPolicy, check that rule's 'from'
# peers include role=client AND that rule's 'ports' include TCP/8080.
check_criterion "A NetworkPolicy allows ingress to app=worker from role=client on TCP/8080" \
  bash -c '
    ns="'"$QUESTION_ID"'"
    for np in $(kubectl get networkpolicy -n "$ns" -o jsonpath="{.items[*].metadata.name}" 2>/dev/null); do
      podsel=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{.spec.podSelector.matchLabels.app}" 2>/dev/null)
      [ "$podsel" = "worker" ] || continue
      nrules=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{range .spec.ingress[*]}x{end}" 2>/dev/null | grep -o x | wc -l)
      i=0
      while [ "$i" -lt "$nrules" ]; do
        peers=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{.spec.ingress[$i].from[*].podSelector.matchLabels.role}" 2>/dev/null)
        ports=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{.spec.ingress[$i].ports[*].port}" 2>/dev/null)
        protos=$(kubectl get networkpolicy "$np" -n "$ns" -o jsonpath="{.spec.ingress[$i].ports[*].protocol}" 2>/dev/null)
        if echo "$peers" | grep -qw client && echo "$ports" | grep -qw 8080 && { [ -z "$protos" ] || echo "$protos" | grep -qw TCP; }; then
          exit 0
        fi
        i=$((i + 1))
      done
    done
    exit 1
  '

print_score
