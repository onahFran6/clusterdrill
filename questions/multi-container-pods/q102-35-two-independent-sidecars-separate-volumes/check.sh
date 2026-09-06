#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-35-two-independent-sidecars-separate-volumes${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'scratch-pad' has exactly 3 containers (main, cache-a, cache-b)" \
  [ "$(kget pod scratch-pad '{.spec.containers[*].name}' -n "$QUESTION_ID")" = "main cache-a cache-b" ]

check_criterion "Pod defines two SEPARATE emptyDir volumes (cache-a-data, cache-b-data)" \
  bash -c "
    a=\$(kubectl get pod scratch-pad -n '$QUESTION_ID' -o jsonpath='{.spec.volumes[?(@.name==\"cache-a-data\")].emptyDir}' 2>/dev/null)
    b=\$(kubectl get pod scratch-pad -n '$QUESTION_ID' -o jsonpath='{.spec.volumes[?(@.name==\"cache-b-data\")].emptyDir}' 2>/dev/null)
    [ \"\$a\" = '{}' ] && [ \"\$b\" = '{}' ]
  "

check_criterion "'cache-a' mounts cache-a-data at /cache, 'cache-b' mounts cache-b-data at /cache (not each other's)" \
  bash -c "
    ca=\$(kubectl get pod scratch-pad -n '$QUESTION_ID' -o jsonpath='{.spec.containers[?(@.name==\"cache-a\")].volumeMounts[?(@.mountPath==\"/cache\")].name}' 2>/dev/null)
    cb=\$(kubectl get pod scratch-pad -n '$QUESTION_ID' -o jsonpath='{.spec.containers[?(@.name==\"cache-b\")].volumeMounts[?(@.mountPath==\"/cache\")].name}' 2>/dev/null)
    [ \"\$ca\" = 'cache-a-data' ] && [ \"\$cb\" = 'cache-b-data' ]
  "

CONTENT_OK=0
for _ in $(seq 1 12); do
  A_CONTENT="$(kubectl exec scratch-pad -c cache-a -n "$QUESTION_ID" -- cat /cache/owner.txt 2>/dev/null)"
  B_CONTENT="$(kubectl exec scratch-pad -c cache-b -n "$QUESTION_ID" -- cat /cache/owner.txt 2>/dev/null)"
  if [ "$A_CONTENT" = "cache-a" ] && [ "$B_CONTENT" = "cache-b" ]; then
    CONTENT_OK=1
    break
  fi
  sleep 3
done
check_criterion "each container's /cache/owner.txt contains only its own name - proving the volumes are NOT shared" \
  [ "$CONTENT_OK" = "1" ]

print_score
