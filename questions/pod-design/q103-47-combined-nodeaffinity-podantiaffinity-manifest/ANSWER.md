# q103-47: reference solution

Doc: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/

```sh
NS=q103-47-combined-nodeaffinity-podantiaffinity-manifest
MANIFEST="$HOME/practice-work/$NS/constrained-worker.yaml"

python3 - "$MANIFEST" <<'PY'
import sys
path = sys.argv[1]
with open(path) as f:
    text = f.read()
affinity = """  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: kubernetes.io/os
                operator: In
                values:
                  - linux
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              app: legacy-worker
          topologyKey: kubernetes.io/hostname
"""
text = text.replace("spec:\n", "spec:\n" + affinity, 1)
with open(path, "w") as f:
    f.write(text)
PY

kubectl apply -f "$MANIFEST"

kubectl wait --for=condition=Ready pod/constrained-worker -n "$NS" --timeout=60s
```
