#!/usr/bin/env bash
# Regression test for #27: verify-question.sh's verify_one() used to skip
# `full_reset (post)` on every early-`return 1` failure path (setup.sh
# fails, unsolved check.sh is a false positive, ANSWER.md fails to apply,
# solved check.sh is a false negative), leaking that question's namespace
# forever. Same self-executing fake-binary pattern as
# tests/bootstrap-minikube_test.sh: this script is symlinked in as a fake
# `kubectl` too, and re-invokes itself in "fake" mode when called that way.
#
# Exercises the "unsolved check.sh is a false positive" failure path
# specifically (check.sh always reports full marks, so the mandatory
# "expect 0, unsolved" assertion fails) - any one of the four failure
# categories exercises the same RETURN-trap fix, so one is representative.

set -euo pipefail

if [[ "${VERIFY_TEST_FAKE:-}" == "1" ]]; then
  case "$1" in
    cluster-info)
      exit 0
      ;;
    api-resources)
      # Empty output either way - NAMESPACED_KINDS/CLUSTER_KINDS end up
      # empty, so verify-question.sh's leaked-object query is skipped
      # entirely. Irrelevant to what this test is checking (cleanup on an
      # early failure path, not leak *detection*).
      exit 0
      ;;
    delete)
      if [[ "$2" == "namespace" ]]; then
        echo "delete namespace $3" >>"$CALL_LOG"
      fi
      exit 0
      ;;
    get)
      # `kubectl get namespace <ns>` (the post-full_reset "did it actually
      # go away" check) - never reached on this test's failure path, but
      # fail closed (as if already gone) in case that changes.
      exit 1
      ;;
    *)
      exit 0
      ;;
  esac
fi

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

FAKE_KUBECTL="$TEST_DIR/kubectl"
CALL_LOG="$TEST_DIR/calls.log"
: >"$CALL_LOG"
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/${0##*/}"
ln -s "$SCRIPT_PATH" "$FAKE_KUBECTL"

QID="qX01-fake-false-positive"
QDIR="$TEST_DIR/questions/fake-topic/$QID"
mkdir -p "$QDIR"
cat >"$QDIR/setup.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"$QDIR/check.sh" <<'EOF'
#!/usr/bin/env bash
# Deliberately always reports full marks, even before the candidate does
# anything - a false positive, the exact "unsolved state scored nonzero"
# failure path this test exercises.
echo "SCORE: 1/1"
EOF
cat >"$QDIR/ANSWER.md" <<'EOF'
# fake reference answer

```sh
true
```
EOF
chmod +x "$QDIR/setup.sh" "$QDIR/check.sh"

BANK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

set +e
PATH="$TEST_DIR:$PATH" \
  CALL_LOG="$CALL_LOG" \
  VERIFY_TEST_FAKE=1 \
  "$BANK_ROOT/lib/verify-question.sh" "$QDIR" >"$TEST_DIR/output.log" 2>&1
status=$?
set -e

if [[ $status -eq 0 ]]; then
  echo "FAIL: verify-question.sh should have exited non-zero for a false-positive check.sh" >&2
  cat "$TEST_DIR/output.log" >&2
  exit 1
fi

if ! grep -q "false positive in check.sh" "$TEST_DIR/output.log"; then
  echo "FAIL: expected output to name the false-positive failure - got:" >&2
  cat "$TEST_DIR/output.log" >&2
  exit 1
fi

# The real assertion: full_reset (pre) always calls `delete namespace`
# once, on its own, regardless of this bug - so a single logged call would
# still be present even completely unfixed. The fix is specifically that a
# SECOND `delete namespace` call happens after the early failure (the
# RETURN-trap cleanup) - one call alone means the leak is still there.
call_count="$(grep -c "^delete namespace ${QID,,}\$" "$CALL_LOG" || true)"
if [[ "$call_count" -lt 2 ]]; then
  echo "FAIL: expected >= 2 'delete namespace $QID' calls (pre-reset + cleanup-on-failure), got $call_count" >&2
  echo "--- call log ---" >&2
  cat "$CALL_LOG" >&2
  echo "--- verify-question.sh output ---" >&2
  cat "$TEST_DIR/output.log" >&2
  exit 1
fi

echo "PASS: verify-question.sh cleans up on an early failure path (#27) - $call_count delete-namespace calls logged"
