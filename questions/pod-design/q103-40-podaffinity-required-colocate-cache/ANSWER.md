# q103-40: reference solution

Doc: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#inter-pod-affinity-and-anti-affinity

```sh
NS=q103-40-podaffinity-required-colocate-cache
MANIFEST="$HOME/practice-work/$NS/replica.yaml"

python3 - "$MANIFEST" <<'PY'
import sys
path = sys.argv[1]
with open(path) as f:
    text = f.read()
affinity = """  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              role: primary
          topologyKey: kubernetes.io/hostname
"""
text = text.replace("spec:\n", "spec:\n" + affinity, 1)
with open(path, "w") as f:
    f.write(text)
PY

kubectl apply -f "$MANIFEST"

kubectl wait --for=condition=Ready pod/replica -n "$NS" --timeout=60s
```
