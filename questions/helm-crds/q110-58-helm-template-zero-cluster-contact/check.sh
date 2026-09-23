#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-58-helm-template-zero-cluster-contact${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
RENDERED_FILE="$WORK_DIR/rendered.yaml"

RENDERED_OK="no"
if [ -f "$RENDERED_FILE" ] && grep -qE "replicas: 4" "$RENDERED_FILE"; then
  RENDERED_OK="yes"
fi
check_criterion "rendered.yaml exists and reflects replicaCount=4" \
  [ "$RENDERED_OK" = "yes" ]

FULL_RENDER="no"
[ "$RENDERED_OK" = "yes" ] && grep -q "busybox:1.36" "$RENDERED_FILE" && FULL_RENDER="yes"
check_criterion "rendered.yaml is a genuine full render (carries the chart default worker image)" \
  [ "$FULL_RENDER" = "yes" ]

# setup.sh's namespace starts empty, so "no Deployment" / "no release" are
# only meaningful once the candidate has proven they actually did the
# rendering task above - otherwise an untouched namespace would trivially
# pass these two by doing nothing at all.
DEPLOYMENT_COUNT="$(kubectl get deployment -n "$QUESTION_ID" -o name 2>/dev/null | wc -l | tr -d ' ')"
NOTHING_INSTALLED="no"
[ "$FULL_RENDER" = "yes" ] && [ "${DEPLOYMENT_COUNT:-1}" = "0" ] && NOTHING_INSTALLED="yes"
check_criterion "Nothing from the chart was actually installed (no Deployment exists)" \
  [ "$NOTHING_INSTALLED" = "yes" ]

NO_RELEASE="no"
if [ "$NOTHING_INSTALLED" = "yes" ] && [ -z "$(helm list -n "$QUESTION_ID" -o json 2>/dev/null | grep -o '"name":')" ]; then
  NO_RELEASE="yes"
fi
check_criterion "No Helm release exists in the namespace (rendering only, never installed)" \
  [ "$NO_RELEASE" = "yes" ]

print_score
