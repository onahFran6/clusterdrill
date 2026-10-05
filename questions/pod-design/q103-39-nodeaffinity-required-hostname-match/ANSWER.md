# q103-39: reference solution

Doc: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity

**Approach A - Fastest (exam default).** `kubectl get nodes` for the node name, then open the
file in vim and paste the affinity block under `spec:` - visible before you save, and the
reflex for any nested field you can't `kubectl set`/`patch` in one line:

```text
kubectl get nodes
vim ~/practice-work/q103-39-nodeaffinity-required-hostname-match/pinned-by-affinity.yaml
/spec:<Enter>
o  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values:
                  - <node-name-from-get-nodes><Esc>
:wq
kubectl apply -f ~/practice-work/q103-39-nodeaffinity-required-hostname-match/pinned-by-affinity.yaml
```

**Approach B - Alternative.** A small Python text-patch - more typing, but deterministic
regardless of the file's exact formatting and easy to script for repeat runs. This is what's
actually executed below for automated verification:

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

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - vim, paste block | medium | low (visible before save) | high - any nested-field addition |
| B - Python patch | high | low but brittle to file changes | low - scripting only |
