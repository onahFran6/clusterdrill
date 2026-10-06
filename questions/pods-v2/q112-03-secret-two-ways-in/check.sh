#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q112-03-secret-two-ways-in${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'db-client' exists, image busybox:1.36" \
  [ "$(kget pod db-client '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Env DB_USER comes from db-creds' user key" \
  bash -c '
    name="$(kubectl get pod db-client -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].env[?(@.name==\"DB_USER\")].valueFrom.secretKeyRef.name}" 2>/dev/null)"
    key="$(kubectl get pod db-client -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].env[?(@.name==\"DB_USER\")].valueFrom.secretKeyRef.key}" 2>/dev/null)"
    [ "$name" = "db-creds" ] && [ "$key" = "user" ]
  '

check_criterion "Secret volume exposes only password at path pass.txt, mode 0400" \
  bash -c '
    volname="$(kubectl get pod db-client -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[0].secret.secretName}" 2>/dev/null)"
    itemkey="$(kubectl get pod db-client -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[0].secret.items[0].key}" 2>/dev/null)"
    itempath="$(kubectl get pod db-client -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[0].secret.items[0].path}" 2>/dev/null)"
    mode="$(kubectl get pod db-client -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[0].secret.defaultMode}" 2>/dev/null)"
    itemcount="$(kubectl get pod db-client -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[0].secret.items}" 2>/dev/null | jq "length")"
    [ "$volname" = "db-creds" ] && [ "$itemkey" = "password" ] && [ "$itempath" = "pass.txt" ] && [ "$mode" = "256" ] && [ "$itemcount" = "1" ]
  '

check_criterion "Volume mounted read-only at /etc/db" \
  bash -c '
    mountpath="$(kubectl get pod db-client -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].volumeMounts[0].mountPath}" 2>/dev/null)"
    readonly="$(kubectl get pod db-client -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].volumeMounts[0].readOnly}" 2>/dev/null)"
    [ "$mountpath" = "/etc/db" ] && [ "$readonly" = "true" ]
  '

check_criterion "Pod is Running" \
  [ "$(kget pod db-client '{.status.phase}' -n "$QUESTION_ID")" = "Running" ]

check_criterion "/etc/db/pass.txt is mode 400 and holds the real password" \
  bash -c '
    mode="$(kubectl exec db-client -n "'"$QUESTION_ID"'" -- stat -L -c %a /etc/db/pass.txt 2>/dev/null)"
    content="$(kubectl exec db-client -n "'"$QUESTION_ID"'" -- cat /etc/db/pass.txt 2>/dev/null)"
    [ "$mode" = "400" ] && [ "$content" = "p@ss w0rd!" ]
  '

check_criterion "DB_USER env var equals app inside the container" \
  bash -c '[ "$(kubectl exec db-client -n "'"$QUESTION_ID"'" -- printenv DB_USER 2>/dev/null)" = "app" ]'

print_score
