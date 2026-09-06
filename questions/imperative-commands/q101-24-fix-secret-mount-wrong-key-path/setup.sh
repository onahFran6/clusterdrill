#!/usr/bin/env bash
# Idempotent: creates/resets namespace q101-24-fix-secret-mount-wrong-key-path
# and seeds a Secret plus a pod whose volume mount references a Secret key
# that does not exist (items[].key: cert.pem instead of tls.crt), so the pod
# fails to start with a volume mount error the candidate must diagnose and
# fix imperatively.

set -euo pipefail

QUESTION_ID="q101-24-fix-secret-mount-wrong-key-path${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Recreate the Secret each run so its data is always the known fixture value
# the check.sh compares against (delete first - `create secret` has no
# apply-style upsert).
kubectl delete secret tls-creds -n "$QUESTION_ID" --ignore-not-found >/dev/null 2>&1

kubectl create secret generic tls-creds \
  --from-literal=tls.crt='-----BEGIN CERTIFICATE-----FIXTURE-CERT-DATA-----END CERTIFICATE-----' \
  --from-literal=tls.key='-----BEGIN PRIVATE KEY-----FIXTURE-KEY-DATA-----END PRIVATE KEY-----' \
  -n "$QUESTION_ID"
kubectl label secret tls-creds -n "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite

# Broken pod: volume's secret.items maps key "cert.pem" (does not exist in
# the Secret - the real keys are tls.crt/tls.key) to path cert.pem, so the
# kubelet cannot project the volume and the pod fails to start.
kubectl delete pod cert-server -n "$QUESTION_ID" --ignore-not-found >/dev/null 2>&1
kubectl wait --for=delete pod/cert-server -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1 || true

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: cert-server
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: cert-server
      image: nginx:1.25-alpine
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: tls
          mountPath: /etc/certs
          readOnly: true
  volumes:
    - name: tls
      secret:
        secretName: tls-creds
        items:
          - key: cert.pem
            path: cert.pem
EOF

echo "setup.sh: $QUESTION_ID ready"
