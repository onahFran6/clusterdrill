#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-49-downwardapi-volume-podinfo${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'metadata-exporter' is Running with labels role=exporter, tier=backend and annotation build.info/version=3.2.1" \
  bash -c '
    phase="$(kubectl get pod metadata-exporter -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$phase" = "Running" ] || exit 1
    role="$(kubectl get pod metadata-exporter -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.role}" 2>/dev/null)"
    [ "$role" = "exporter" ] || exit 1
    tier="$(kubectl get pod metadata-exporter -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.tier}" 2>/dev/null)"
    [ "$tier" = "backend" ] || exit 1
    ver="$(kubectl get pod metadata-exporter -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.annotations.build\.info/version}" 2>/dev/null)"
    [ "$ver" = "3.2.1" ]
  '

# Requires a non-empty match, not just an equal one - if the pod doesn't
# exist yet, both jsonpath queries return "", which would otherwise compare
# equal (false positive) before the candidate does anything.
check_criterion "Pod has a downwardAPI volume mounted at /etc/podinfo" \
  bash -c '
    vol_name="$(kubectl get pod metadata-exporter -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[?(@.downwardAPI)].name}" 2>/dev/null)"
    mount_name="$(kubectl get pod metadata-exporter -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].volumeMounts[?(@.mountPath==\"/etc/podinfo\")].name}" 2>/dev/null)"
    [ -n "$vol_name" ] && [ "$vol_name" = "$mount_name" ]
  '

check_criterion "/etc/podinfo/pod-name contains metadata-exporter" \
  [ "$(kubectl exec -n "$QUESTION_ID" metadata-exporter -- cat /etc/podinfo/pod-name 2>/dev/null)" = "metadata-exporter" ]

check_criterion "/etc/podinfo/labels contains role=\"exporter\"" \
  bash -c '
    content="$(kubectl exec -n "'"$QUESTION_ID"'" metadata-exporter -- cat /etc/podinfo/labels 2>/dev/null)"
    case "$content" in
      *role=\"exporter\"*) exit 0 ;;
      *) exit 1 ;;
    esac
  '

check_criterion "/etc/podinfo/annotations contains build.info/version=\"3.2.1\"" \
  bash -c '
    content="$(kubectl exec -n "'"$QUESTION_ID"'" metadata-exporter -- cat /etc/podinfo/annotations 2>/dev/null)"
    case "$content" in
      *build.info/version=\"3.2.1\"*) exit 0 ;;
      *) exit 1 ;;
    esac
  '

print_score
