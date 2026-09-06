#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q107-12-debug-distroless-copy${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Debug copy pod 'minimal-svc-debug' exists" \
  resource_exists pod minimal-svc-debug -n "$QUESTION_ID"

container_names="$(kget pod minimal-svc-debug '{.spec.containers[*].name}' -n "$QUESTION_ID")"

check_criterion "Debug copy still has the original 'minimal-svc' container" \
  bash -c "case ' $container_names ' in *' minimal-svc '*) exit 0;; *) exit 1;; esac"

check_criterion "Debug copy has a new 'debugger' container" \
  bash -c "case ' $container_names ' in *' debugger '*) exit 0;; *) exit 1;; esac"

check_criterion "'debugger' container uses image busybox:1.36" \
  [ "$(kget pod minimal-svc-debug '{.spec.containers[?(@.name=="debugger")].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

print_score
