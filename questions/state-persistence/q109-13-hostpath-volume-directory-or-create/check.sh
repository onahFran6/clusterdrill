#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q109-13-hostpath-volume-directory-or-create${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'log-writer' exists" \
  resource_exists pod log-writer -n "$QUESTION_ID"

check_criterion "Volume 'hostlogs' hostPath.path is /tmp/ckad-hostlogs" \
  [ "$(kget pod log-writer '{.spec.volumes[0].hostPath.path}' -n "$QUESTION_ID")" = "/tmp/ckad-hostlogs" ]

check_criterion "Volume 'hostlogs' hostPath.type is DirectoryOrCreate" \
  [ "$(kget pod log-writer '{.spec.volumes[0].hostPath.type}' -n "$QUESTION_ID")" = "DirectoryOrCreate" ]

check_criterion "Container mounts the volume at /var/log/app" \
  [ "$(kget pod log-writer '{.spec.containers[0].volumeMounts[0].mountPath}' -n "$QUESTION_ID")" = "/var/log/app" ]

kubectl wait --for=condition=Ready pod/log-writer -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1

check_criterion "/var/log/app exists as a directory inside the container" \
  bash -c "kubectl exec -n '$QUESTION_ID' log-writer -- test -d /var/log/app"

print_score
