#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q112-19-projected-volume-everything-in-one-directory${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "A single projected volume merges all 4 sources (plus whatever Kubernetes auto-mounts)" \
  bash -c '
    kubectl get pod bundle -n "'"$QUESTION_ID"'" -o json 2>/dev/null | \
      jq -e "[.spec.volumes[] | select(.projected.sources != null and (.projected.sources | length) == 4)] | length == 1" >/dev/null
  '

check_criterion "ConfigMap source exposes app-cfg's app.yaml at path app.yaml" \
  bash -c '
    kubectl get pod bundle -n "'"$QUESTION_ID"'" -o json 2>/dev/null | \
      jq -e "[(.spec.volumes[] | select(.projected.sources != null and (.projected.sources | length) == 4) | .projected.sources[]) | select(.configMap.name==\"app-cfg\") | .configMap.items[] | select(.key==\"app.yaml\" and .path==\"app.yaml\")] | length == 1" >/dev/null
  '

check_criterion "Secret source exposes app-sec's token at path secret/token" \
  bash -c '
    kubectl get pod bundle -n "'"$QUESTION_ID"'" -o json 2>/dev/null | \
      jq -e "[(.spec.volumes[] | select(.projected.sources != null and (.projected.sources | length) == 4) | .projected.sources[]) | select(.secret.name==\"app-sec\") | .secret.items[] | select(.key==\"token\" and .path==\"secret/token\")] | length == 1" >/dev/null
  '

check_criterion "downwardAPI source exposes the Pod's labels at path meta/labels" \
  bash -c '
    kubectl get pod bundle -n "'"$QUESTION_ID"'" -o json 2>/dev/null | \
      jq -e "[(.spec.volumes[] | select(.projected.sources != null and (.projected.sources | length) == 4) | .projected.sources[]) | select(.downwardAPI) | .downwardAPI.items[] | select(.path==\"meta/labels\" and .fieldRef.fieldPath==\"metadata.labels\")] | length == 1" >/dev/null
  '

check_criterion "serviceAccountToken source: audience vault, 3600s, path vault-token" \
  bash -c '
    kubectl get pod bundle -n "'"$QUESTION_ID"'" -o json 2>/dev/null | \
      jq -e "[(.spec.volumes[] | select(.projected.sources != null and (.projected.sources | length) == 4) | .projected.sources[]) | select(.serviceAccountToken.audience==\"vault\" and .serviceAccountToken.expirationSeconds==3600 and .serviceAccountToken.path==\"vault-token\")] | length == 1" >/dev/null
  '

check_criterion "Pod is Running, label app=bundle" \
  bash -c '
    app="$(kubectl get pod bundle -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.app}" 2>/dev/null)"
    phase="$(kubectl get pod bundle -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$app" = "bundle" ] && [ "$phase" = "Running" ]
  '

check_criterion "ls -R /etc/bundle shows all four expected paths" \
  bash -c '
    out="$(kubectl exec bundle -n "'"$QUESTION_ID"'" -- ls -R /etc/bundle 2>/dev/null)"
    echo "$out" | grep -q "app.yaml" && echo "$out" | grep -q "secret" && echo "$out" | grep -q "meta" && echo "$out" | grep -q "vault-token"
  '

print_score
