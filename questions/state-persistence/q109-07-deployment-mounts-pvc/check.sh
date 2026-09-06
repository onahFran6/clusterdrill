#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-07-deployment-mounts-pvc${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'uploads-api' exists in $QUESTION_ID" \
  resource_exists deployment uploads-api -n "$QUESTION_ID"

check_criterion "Deployment has exactly 1 replica" \
  [ "$(kget deployment uploads-api '{.spec.replicas}' -n "$QUESTION_ID")" = "1" ]

check_criterion "Volume 'uploads-storage' references PVC uploads-pvc" \
  [ "$(kget deployment uploads-api '{.spec.template.spec.volumes[?(@.name=="uploads-storage")].persistentVolumeClaim.claimName}' -n "$QUESTION_ID")" = "uploads-pvc" ]

check_criterion "Container 'api' mounts 'uploads-storage' at /usr/share/nginx/html/uploads" \
  [ "$(kget deployment uploads-api '{.spec.template.spec.containers[0].volumeMounts[?(@.name=="uploads-storage")].mountPath}' -n "$QUESTION_ID")" = "/usr/share/nginx/html/uploads" ]

check_criterion "Deployment is available (1 ready replica)" \
  [ "$(kget deployment uploads-api '{.status.readyReplicas}' -n "$QUESTION_ID")" = "1" ]

print_score
