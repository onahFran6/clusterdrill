#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q108-28-diagnose-dns-wrong-namespace-suffix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
FRONTEND_NS="${QUESTION_ID}-frontend"
BACKEND_NS="${QUESTION_ID}-backend"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

EXPECTED_URL="http://orders-svc.${BACKEND_NS}.svc.cluster.local:8080/"
ACTUAL_URL="$(kget deployment web-ui '{.spec.template.spec.containers[0].env[?(@.name=="ORDERS_URL")].value}' -n "$FRONTEND_NS")"

URL_FIXED="no"
if [ "$ACTUAL_URL" = "$EXPECTED_URL" ]; then
  URL_FIXED="yes"
fi

# Bundle the env-var check together with an actual rollout-ready check: on
# the unsolved state the env var is wrong AND the pod is CrashLoopBackOff, so
# this criterion is false immediately after setup.sh (satisfies the "unsolved
# state scores 0" gate) and only becomes true once the candidate has both
# fixed the value and the Deployment has actually rolled out healthy pods.
ROLLOUT_OK="no"
if [ "$URL_FIXED" = "yes" ] && kubectl rollout status deployment/web-ui -n "$FRONTEND_NS" --timeout=90s >/dev/null 2>&1; then
  ROLLOUT_OK="yes"
fi

check_criterion "web-ui Deployment's ORDERS_URL env var points at the real backend namespace ($EXPECTED_URL)" \
  [ "$URL_FIXED" = "yes" ]

check_criterion "web-ui Deployment rolled out successfully after the fix" \
  [ "$ROLLOUT_OK" = "yes" ]

READY_OK="no"
if [ "$ROLLOUT_OK" = "yes" ]; then
  # Use the Deployment's own status (readyReplicas vs spec.replicas) rather
  # than snapshotting `kubectl get pods`: a just-superseded old ReplicaSet's
  # pod can sit Terminating for a few seconds after a rollout completes,
  # which a raw pod-list snapshot would still catch and misreport as "not
  # ready". kubectl rollout status above already waited for the rollout to
  # settle, so this is just a final confirmation of Ready 1/1.
  DESIRED="$(kget deployment web-ui '{.spec.replicas}' -n "$FRONTEND_NS")"
  READY="$(kget deployment web-ui '{.status.readyReplicas}' -n "$FRONTEND_NS")"
  if [ -n "$DESIRED" ] && [ "$DESIRED" = "$READY" ]; then
    READY_OK="yes"
  fi
fi
check_criterion "web-ui pod(s) are Ready 1/1" \
  [ "$READY_OK" = "yes" ]

# Fresh exec-curl from a throwaway debug pod in the frontend namespace,
# using the exact URL currently configured on the Deployment, proves the DNS
# name actually resolves and serves HTTP 200 end-to-end - not just that the
# string looks right.
CURL_OK="no"
if [ "$ROLLOUT_OK" = "yes" ]; then
  kubectl delete pod dns-debug -n "$FRONTEND_NS" --ignore-not-found --wait=true >/dev/null 2>&1
  kubectl run dns-debug -n "$FRONTEND_NS" --restart=Never --image=nicolaka/netshoot:latest \
    --overrides='{"spec":{"containers":[{"name":"dns-debug","image":"nicolaka/netshoot:latest","command":["curl","-s","-o","/dev/null","-w","%{http_code}","'"$ACTUAL_URL"'"],"resources":{"requests":{"cpu":"25m","memory":"32Mi"},"limits":{"cpu":"50m","memory":"64Mi"}}}]}}' \
    >/dev/null 2>&1
  kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/dns-debug -n "$FRONTEND_NS" --timeout=60s >/dev/null 2>&1
  HTTP_CODE="$(kubectl logs dns-debug -n "$FRONTEND_NS" 2>/dev/null)"
  if [ "$HTTP_CODE" = "200" ]; then
    CURL_OK="yes"
  fi
  kubectl delete pod dns-debug -n "$FRONTEND_NS" --ignore-not-found --wait=false >/dev/null 2>&1
fi
check_criterion "Fresh debug pod can curl ORDERS_URL and get HTTP 200" \
  [ "$CURL_OK" = "yes" ]

print_score
