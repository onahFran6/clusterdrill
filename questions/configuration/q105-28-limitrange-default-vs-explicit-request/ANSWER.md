# q105-28-limitrange-default-vs-explicit-request: reference solution

Doc: https://kubernetes.io/docs/concepts/policy/limit-range/

```sh
QUESTION_ID="q105-28-limitrange-default-vs-explicit-request"
WORK_DIR="$HOME/practice-work/$QUESTION_ID"
mkdir -p "$WORK_DIR"

# Reproduce the candidate's starting file in case this is being run
# standalone (verify-question.sh applies ANSWER.md on its own, without a
# live terminal session that already has setup.sh's seeded file).
cat > "$WORK_DIR/bigmem.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: bigmem
spec:
  containers:
    - name: bigmem
      image: nginx:1.25-alpine
      resources:
        limits:
          memory: 512Mi
EOF

# First attempt is rejected: 512Mi exceeds the LimitRange's 256Mi max.
kubectl apply -n "$QUESTION_ID" -f "$WORK_DIR/bigmem.yaml" || true

# Fix: lower the memory limit to 200Mi. Kubernetes defaults an unset
# request to match an explicitly-set limit on the same container (it does
# NOT fall back to the LimitRange's defaultRequest once a limit is
# present), so the request must be set explicitly to 128Mi here to match
# the LimitRange's own default request value.
cat > "$WORK_DIR/bigmem.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: bigmem
spec:
  containers:
    - name: bigmem
      image: nginx:1.25-alpine
      resources:
        limits:
          memory: 200Mi
        requests:
          memory: 128Mi
EOF

kubectl apply -n "$QUESTION_ID" -f "$WORK_DIR/bigmem.yaml"

kubectl wait --for=condition=Ready pod/bigmem -n "$QUESTION_ID" --timeout=60s
```
