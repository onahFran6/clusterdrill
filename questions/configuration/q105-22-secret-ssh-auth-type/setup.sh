#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-22-secret-ssh-auth-type, writes
# the source private-key file to this question's terminal working
# directory, and seeds the starting pod.

set -euo pipefail

QUESTION_ID="q105-22-secret-ssh-auth-type${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Placeholder key content, not a real key - this question's terminal
# working directory (see question_workdir() in lib/grading.sh), matching
# where the candidate's terminal actually starts.
WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/id_rsa" <<'EOF'
-----BEGIN OPENSSH PRIVATE KEY-----
q105-22-placeholder-not-a-real-key-just-file-contents-to-copy-into-a-secret
-----END OPENSSH PRIVATE KEY-----
EOF
chmod 600 "$WORK_DIR/id_rsa"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: deploy-agent
  labels:
    app: deploy-agent
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: deploy-agent
      image: nginx:1.25-alpine
EOF

kubectl wait --for=condition=Ready pod/deploy-agent -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
