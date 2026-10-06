# q103-40: reference solution

Doc: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#inter-pod-affinity-and-anti-affinity

**Approach A - Fastest (exam default).** Open the file in vim and paste the affinity block under
`spec:` - visible before you save, and the reflex for any nested field:

```text
vim ~/practice-work/q103-40-podaffinity-required-colocate-cache/replica.yaml
/spec:<Enter>
o  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              role: primary
          topologyKey: kubernetes.io/hostname<Esc>
:wq
kubectl apply -f ~/practice-work/q103-40-podaffinity-required-colocate-cache/replica.yaml
```

**Approach B - Alternative.** A small Python text-patch - more typing, but deterministic
regardless of the file's exact formatting. This is what's actually executed below for automated
verification:

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

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - vim, paste block | medium | low (visible before save) | high - any nested-field addition |
| B - Python patch | high | low but brittle to file changes | low - scripting only |
