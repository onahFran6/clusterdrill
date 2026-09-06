#!/usr/bin/env bash

set -euo pipefail

if [[ "${BOOTSTRAP_TEST_FAKE:-}" == "1" ]]; then
  case "${0##*/}:${1:-}:${2:-}" in
    minikube:status:*)
      printf 'Running\n'
      exit 0
      ;;
    minikube:update-context:*)
      exit 0
      ;;
    minikube:addons:list)
      if [[ "${ADDON_TEST_STATE:-disabled}" == "enabled" ]]; then
        printf '%s\n' \
          '{' \
          '  "ingress": {' \
          '    "Profile": "clusterdrill",' \
          '    "Status": "enabled"' \
          '  },' \
          '  "metrics-server": {' \
          '    "Profile": "clusterdrill",' \
          '    "Status": "enabled"' \
          '  }' \
          '}'
      else
        printf '%s\n' '{"ingress":{"Profile":"clusterdrill","Status":"disabled"},"metrics-server":{"Profile":"clusterdrill","Status":"disabled"}}'
      fi
      exit 0
      ;;
    minikube:addons:enable)
      printf '%s\n' "$3" >>"$ADDON_TEST_CALL_LOG"
      if [[ "${ADDON_TEST_FAIL_ONCE:-0}" == "1" && ! -e "$ADDON_TEST_FAILURE_MARKER" ]]; then
        : >"$ADDON_TEST_FAILURE_MARKER"
        exit 1
      fi
      exit 0
      ;;
    kubectl:config:use-context)
      exit 0
      ;;
    kubectl:config:current-context)
      printf 'clusterdrill\n'
      exit 0
      ;;
    kubectl:get:nodes)
      printf 'NAME STATUS\nclusterdrill Ready\n'
      exit 0
      ;;
    *)
      exit 1
      ;;
  esac
fi

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

FAKE_MINIKUBE="$TEST_DIR/minikube"
FAKE_KUBECTL="$TEST_DIR/kubectl"
CALL_LOG="$TEST_DIR/calls.log"
FAILURE_MARKER="$TEST_DIR/failed-once"
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/${0##*/}"
ln -s "$SCRIPT_PATH" "$FAKE_MINIKUBE"
ln -s "$SCRIPT_PATH" "$FAKE_KUBECTL"

run_bootstrap() {
  ADDON_TEST_STATE="$1" \
    ADDON_TEST_CALL_LOG="$CALL_LOG" \
    ADDON_TEST_FAILURE_MARKER="$FAILURE_MARKER" \
    ADDON_TEST_FAIL_ONCE="${2:-0}" \
    BOOTSTRAP_TEST_FAKE=1 \
    MINIKUBE_BIN="$FAKE_MINIKUBE" \
    KUBECTL_BIN="$FAKE_KUBECTL" \
    lib/bootstrap-minikube.sh
}

run_bootstrap disabled >"$TEST_DIR/disabled.out"
if [[ "$(sort "$CALL_LOG")" != $'ingress\nmetrics-server' ]]; then
  printf 'expected both disabled addons to be enabled\n' >&2
  exit 1
fi

: >"$CALL_LOG"
run_bootstrap enabled >"$TEST_DIR/enabled.out"
if [[ -s "$CALL_LOG" ]]; then
  printf 'expected enabled addons to be skipped\n' >&2
  exit 1
fi

grep -Fq "addon 'ingress' is already enabled - skipping." "$TEST_DIR/enabled.out"
grep -Fq "addon 'metrics-server' is already enabled - skipping." "$TEST_DIR/enabled.out"

rm -f "$FAILURE_MARKER"
: >"$CALL_LOG"
run_bootstrap disabled 1 >"$TEST_DIR/retry.out" 2>"$TEST_DIR/retry.err"
if [[ "$(grep -c '^ingress$' "$CALL_LOG")" != "2" ]]; then
  printf 'expected a failed addon enable to be retried once\n' >&2
  exit 1
fi
grep -Fq "did not complete on the first attempt - retrying once." "$TEST_DIR/retry.err"

printf 'bootstrap-minikube tests passed\n'
