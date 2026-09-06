#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
#
# The kubelet resyncs projected/ConfigMap volumes on a periodic cache TTL
# (about a minute), not instantly - this check polls with a generous
# timeout instead of checking once, so a correct solution isn't scored as a
# failure just because grading ran a few seconds too early.
set -uo pipefail

QUESTION_ID="q105-16-configmap-projected-volume-live-update${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'banner-config' banner.txt key was updated to v2-updated" \
  [ "$(kget configmap banner-config '{.data.banner\.txt}' -n "$QUESTION_ID")" = "v2-updated" ]

# Poll up to ~100s for the kubelet's projected-volume resync to propagate
# the new ConfigMap content into the already-running container.
_propagated="false"
for _ in $(seq 1 20); do
  _content="$(kubectl exec -n "$QUESTION_ID" banner-app -- cat /etc/banner/banner.txt 2>/dev/null)"
  if [ "$_content" = "v2-updated" ]; then
    _propagated="true"
    break
  fi
  sleep 5
done

check_criterion "Updated content (v2-updated) propagated into the running container's mounted file" \
  [ "$_propagated" = "true" ]

print_score
