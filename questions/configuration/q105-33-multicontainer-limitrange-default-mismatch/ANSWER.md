# q105-33-multicontainer-limitrange-default-mismatch: reference solution

Doc: https://kubernetes.io/docs/concepts/policy/limit-range/

```sh
QUESTION_ID="q105-33-multicontainer-limitrange-default-mismatch"
WORK_DIR="$HOME/practice-work/$QUESTION_ID"
mkdir -p "$WORK_DIR"

# Reproduce the candidate's starting file in case this is being run
# standalone (verify-question.sh applies ANSWER.md on its own, without a
# live terminal session that already has setup.sh's seeded file).
cat > "$WORK_DIR/worker.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: worker
  labels:
    app: worker
spec:
  containers:
    - name: collector
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
    - name: shipper
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      resources:
        limits:
          memory: "256Mi"
EOF

# Apply as-is first: this is admitted successfully (a container may set a
# limit with no request), but 'shipper' ends up requesting 256Mi -
# Kubernetes derives an unset request from an explicit limit on the SAME
# container, not from the LimitRange's defaultRequest, once that limit is
# present.
kubectl apply -n "$QUESTION_ID" -f "$WORK_DIR/worker.yaml"
kubectl wait --for=condition=Ready pod/worker -n "$QUESTION_ID" --timeout=60s

# Fix: give 'shipper' an explicit 64Mi request (matching the capacity
# plan's baseline) while keeping its 256Mi limit untouched. 'collector' is
# left alone - it already inherits the LimitRange's 128Mi default limit /
# 64Mi default request because it declares no resources at all.
cat > "$WORK_DIR/worker.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: worker
  labels:
    app: worker
spec:
  containers:
    - name: collector
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
    - name: shipper
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      resources:
        limits:
          memory: "256Mi"
        requests:
          memory: "64Mi"
EOF

# The pod's containers[].resources are immutable once created - delete and
# recreate for the fix to take effect.
kubectl delete pod worker -n "$QUESTION_ID"
kubectl apply -n "$QUESTION_ID" -f "$WORK_DIR/worker.yaml"
kubectl wait --for=condition=Ready pod/worker -n "$QUESTION_ID" --timeout=60s
```
