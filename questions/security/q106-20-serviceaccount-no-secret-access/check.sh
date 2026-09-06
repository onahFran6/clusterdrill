#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-20-serviceaccount-no-secret-access${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "web-frontend ServiceAccount still exists AND cannot get Secrets in this namespace" \
  bash -c "kubectl get serviceaccount web-frontend -n '$QUESTION_ID' >/dev/null 2>&1 && \
    kubectl auth can-i get secrets \
      --as=system:serviceaccount:${QUESTION_ID}:web-frontend -n ${QUESTION_ID} | grep -q '^no'"

check_criterion "web-frontend ServiceAccount still exists AND cannot list Secrets in this namespace" \
  bash -c "kubectl get serviceaccount web-frontend -n '$QUESTION_ID' >/dev/null 2>&1 && \
    kubectl auth can-i list secrets \
      --as=system:serviceaccount:${QUESTION_ID}:web-frontend -n ${QUESTION_ID} | grep -q '^no'"

print_score
