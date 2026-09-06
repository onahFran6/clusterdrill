#!/usr/bin/env bash
# Concatenates every questions/<topic>/domains.fragment.yaml into a single
# runtime schema. No topic ever edits a shared file directly - this script is what reassembles the fragments
# for anything that needs the whole-bank view (grading reports, the
# diagram generator, gamification's domain-mastery checks).
#
# Usage:
#   lib/load-domains.sh                 # write .generated/domains.yaml, print to stdout
#   lib/load-domains.sh -o path/out.yaml # write to a custom path instead
#   lib/load-domains.sh --check         # validate fragments only, write nothing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BANK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
QUESTIONS_DIR="$BANK_ROOT/questions"
DEFAULT_OUT="$BANK_ROOT/.generated/domains.yaml"

OUT_PATH="$DEFAULT_OUT"
CHECK_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output)
      OUT_PATH="$2"
      shift 2
      ;;
    --check)
      CHECK_ONLY=1
      shift
      ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "load-domains.sh: unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if ! command -v python3 >/dev/null 2>&1; then
  echo "load-domains.sh: python3 is required (used for YAML merging) but not found on PATH" >&2
  exit 1
fi

python3 - "$QUESTIONS_DIR" "$OUT_PATH" "$CHECK_ONLY" <<'PYEOF'
import sys
import glob
import os

try:
    import yaml
except ImportError:
    print("load-domains.sh: PyYAML is required (pip install pyyaml)", file=sys.stderr)
    sys.exit(1)

questions_dir, out_path, check_only = sys.argv[1], sys.argv[2], sys.argv[3] == "1"

fragment_paths = sorted(glob.glob(os.path.join(questions_dir, "*", "domains.fragment.yaml")))

merged_questions = []
seen_ids = {}
errors = []

for path in fragment_paths:
    topic_dir = os.path.basename(os.path.dirname(path))
    with open(path) as f:
        try:
            fragment = yaml.safe_load(f) or {}
        except yaml.YAMLError as e:
            errors.append(f"{path}: invalid YAML ({e})")
            continue

    topic = fragment.get("topic", topic_dir)
    if topic != topic_dir:
        errors.append(f"{path}: 'topic: {topic}' does not match directory name '{topic_dir}'")

    questions = fragment.get("questions", [])
    if not isinstance(questions, list):
        errors.append(f"{path}: 'questions' must be a list")
        continue

    for q in questions:
        qid = q.get("id")
        if not qid:
            errors.append(f"{path}: question entry missing 'id': {q}")
            continue
        if qid in seen_ids:
            errors.append(f"{path}: duplicate question id '{qid}' (also in {seen_ids[qid]})")
            continue
        seen_ids[qid] = path
        requirements = q.get("requirements")
        min_nodes = requirements.get("min_nodes") if isinstance(requirements, dict) else None
        if isinstance(min_nodes, bool) or not isinstance(min_nodes, int) or min_nodes < 1:
            errors.append(f"{path}: question '{qid}' requires requirements.min_nodes as an integer >= 1")
        entry = dict(q)
        entry["topic"] = topic_dir
        merged_questions.append(entry)

# Fragment metadata is an audited contract, not an optional UI hint. Every
# runnable question directory must be represented exactly once.
for question_md in glob.glob(os.path.join(questions_dir, "*", "q*", "QUESTION.md")):
    if not os.path.isfile(os.path.join(os.path.dirname(question_md), "check.sh")):
        continue
    qid = os.path.basename(os.path.dirname(question_md))
    if qid not in seen_ids:
        errors.append(f"{question_md}: runnable question is missing fragment metadata")

if errors:
    print("load-domains.sh: fragment validation failed:", file=sys.stderr)
    for e in errors:
        print(f"  - {e}", file=sys.stderr)
    sys.exit(1)

if check_only:
    print(f"load-domains.sh: {len(fragment_paths)} fragment(s), {len(merged_questions)} question(s) - all valid")
    sys.exit(0)

merged = {"questions": merged_questions}
rendered = yaml.dump(merged, sort_keys=False, default_flow_style=False)

os.makedirs(os.path.dirname(out_path), exist_ok=True)
with open(out_path, "w") as f:
    f.write(rendered)

print(rendered, end="")
print(f"# load-domains.sh: wrote {len(merged_questions)} question(s) from {len(fragment_paths)} fragment(s) to {out_path}", file=sys.stderr)
PYEOF
