#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-10-create-secret-generic${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Secret 'db-creds' exists in $QUESTION_ID" \
  resource_exists secret db-creds -n "$QUESTION_ID"

check_criterion "Secret 'db-creds' is of type Opaque" \
  [ "$(kget secret db-creds '{.type}' -n "$QUESTION_ID")" = "Opaque" ]

check_criterion "Secret 'db-creds' decodes username=admin" \
  [ "$(kget secret db-creds '{.data.username}' -n "$QUESTION_ID" | base64 -d)" = "admin" ]

check_criterion "Secret 'db-creds' decodes password=S3cr3t!" \
  [ "$(kget secret db-creds '{.data.password}' -n "$QUESTION_ID" | base64 -d)" = "S3cr3t!" ]

print_score
