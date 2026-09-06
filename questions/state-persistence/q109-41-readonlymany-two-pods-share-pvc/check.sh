#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-41-readonlymany-two-pods-share-pvc${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

for pod in catalog-reader-a catalog-reader-b; do
  check_criterion "Pod '$pod' exists and is Running" \
    bash -c "[ \"\$(kubectl get pod $pod -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)\" = 'Running' ]"

  check_criterion "Pod '$pod' mounts catalog-claim read-only at /catalog" \
    bash -c '
      vol="$(kubectl get pod '"$pod"' -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[?(@.persistentVolumeClaim.claimName==\"catalog-claim\")].name}" 2>/dev/null)"
      [ -n "$vol" ] || exit 1
      mount_path="$(kubectl get pod '"$pod"' -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].volumeMounts[?(@.name==\"$vol\")].mountPath}" 2>/dev/null)"
      read_only="$(kubectl get pod '"$pod"' -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].volumeMounts[?(@.name==\"$vol\")].readOnly}" 2>/dev/null)"
      [ "$mount_path" = "/catalog" ] && [ "$read_only" = "true" ]
    '
done

check_criterion "Both Pods are running simultaneously (ReadOnlyMany shared access)" \
  bash -c "[ \"\$(kubectl get pod catalog-reader-a -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)\" = 'Running' ] && \
    [ \"\$(kubectl get pod catalog-reader-b -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)\" = 'Running' ]"

print_score
