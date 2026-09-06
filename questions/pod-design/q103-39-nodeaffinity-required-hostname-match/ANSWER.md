# q103-39: reference solution

Doc: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity

```sh
NS=q103-39-nodeaffinity-required-hostname-match
MANIFEST="$HOME/practice-work/$NS/pinned-by-affinity.yaml"

TARGET_NODE="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')"

python3 - "$MANIFEST" "$TARGET_NODE" <<'PY'
import sys
path, node = sys.argv[1], sys.argv[2]
with open(path) as f:
    text = f.read()
affinity = f"""  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values:
                  - {node}
"""
text = text.replace("spec:\n", "spec:\n" + affinity, 1)
with open(path, "w") as f:
    f.write(text)
PY

kubectl apply -f "$MANIFEST"

kubectl wait --for=condition=Ready pod/pinned-by-affinity -n "$NS" --timeout=60s
```
