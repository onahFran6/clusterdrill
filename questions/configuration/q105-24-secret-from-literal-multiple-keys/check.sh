#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-24-secret-from-literal-multiple-keys${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Secret 'db-creds' exists with exactly two keys (username, password)" \
  bash -c "[ \"\$(kubectl get secret db-creds -n '$QUESTION_ID' -o jsonpath='{.data}' 2>/dev/null | grep -o '\"[a-zA-Z]*\":' | sort -u | wc -l | tr -d ' ')\" = '2' ] && [ -n \"\$(kubectl get secret db-creds -n '$QUESTION_ID' -o jsonpath='{.data.username}' 2>/dev/null)\" ] && [ -n \"\$(kubectl get secret db-creds -n '$QUESTION_ID' -o jsonpath='{.data.password}' 2>/dev/null)\" ]"

check_criterion "Secret 'db-creds' key password decodes to S3cr3t!" \
  [ "$(kubectl get secret db-creds -n "$QUESTION_ID" -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null)" = "S3cr3t!" ]

check_criterion "Pod 'dbclient' is Running" \
  [ "$(kget pod dbclient '{.status.phase}' -n "$QUESTION_ID")" = "Running" ]

check_criterion "/etc/db/password inside the pod contains exactly S3cr3t!" \
  [ "$(kubectl exec -n "$QUESTION_ID" dbclient -- cat /etc/db/password 2>/dev/null)" = "S3cr3t!" ]

check_criterion "Pod is Running, password is mounted, and username is exposed nowhere (no file, no env var)" \
  bash -c "[ \"\$(kubectl get pod dbclient -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)\" = 'Running' ] && kubectl exec -n '$QUESTION_ID' dbclient -- test -f /etc/db/password 2>/dev/null && ! kubectl exec -n '$QUESTION_ID' dbclient -- test -e /etc/db/username 2>/dev/null && ! kubectl exec -n '$QUESTION_ID' dbclient -- sh -c 'env' 2>/dev/null | grep -q 'admin'"

print_score
