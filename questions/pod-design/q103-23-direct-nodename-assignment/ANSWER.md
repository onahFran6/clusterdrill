# q103-23: reference solution

Doc: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodename

```sh
QUESTION_ID="q103-23-direct-nodename-assignment"
MANIFEST="$HOME/practice-work/$QUESTION_ID/node-pinned.yaml"

TARGET_NODE="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')"

# Add spec.nodeName to the manifest before creating the pod - nodeName is
# immutable once the pod exists, so it must be set at creation time.
python3 - "$MANIFEST" "$TARGET_NODE" <<'PY'
import sys
path, node = sys.argv[1], sys.argv[2]
with open(path) as f:
    text = f.read()
text = text.replace("spec:\n", f"spec:\n  nodeName: {node}\n", 1)
with open(path, "w") as f:
    f.write(text)
PY

kubectl apply -f "$MANIFEST"

kubectl wait --for=condition=Ready "pod/node-pinned" -n "$QUESTION_ID" --timeout=60s
kubectl get pod node-pinned -n "$QUESTION_ID" -o jsonpath='{.spec.nodeName}'
```
