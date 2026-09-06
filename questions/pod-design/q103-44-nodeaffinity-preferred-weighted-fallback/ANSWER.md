# q103-44: reference solution

Doc: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity

```sh
NS=q103-44-nodeaffinity-preferred-weighted-fallback
MANIFEST="$HOME/practice-work/$NS/flexible-worker.yaml"

python3 - "$MANIFEST" <<'PY'
import sys
path = sys.argv[1]
with open(path) as f:
    text = f.read()
affinity = """  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 80
          preference:
            matchExpressions:
              - key: kubernetes.io/os
                operator: In
                values:
                  - linux
        - weight: 20
          preference:
            matchExpressions:
              - key: kubernetes.io/arch
                operator: In
                values:
                  - arm64
"""
text = text.replace("spec:\n", "spec:\n" + affinity, 1)
with open(path, "w") as f:
    f.write(text)
PY

kubectl apply -f "$MANIFEST"

kubectl wait --for=condition=Ready pod/flexible-worker -n "$NS" --timeout=60s
```
