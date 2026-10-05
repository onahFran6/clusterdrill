# q103-34: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination

**Approach A - Fastest (exam default).** Open the file in vim and add the one field - visible on
screen before you save, and the reflex that works for adding any missing field:

```text
vim ~/practice-work/q103-34-pod-terminationgraceperiod-window/slow-shutdown.yaml
/spec:<Enter>
o  terminationGracePeriodSeconds: 90<Esc>
:wq
kubectl apply -f ~/practice-work/q103-34-pod-terminationgraceperiod-window/slow-shutdown.yaml
```

**Approach B - Alternative.** A small Python text-patch - more typing and less reusable as a
reflex, but deterministic regardless of the file's exact formatting. This is what's actually
executed below for automated verification:

```sh
NS=q103-34-pod-terminationgraceperiod-window
MANIFEST="$HOME/practice-work/$NS/slow-shutdown.yaml"

python3 - "$MANIFEST" <<'PY'
import sys
path = sys.argv[1]
with open(path) as f:
    text = f.read()
text = text.replace("spec:\n", "spec:\n  terminationGracePeriodSeconds: 90\n", 1)
with open(path, "w") as f:
    f.write(text)
PY

kubectl apply -f "$MANIFEST"

kubectl wait --for=condition=Ready pod/slow-shutdown -n "$NS" --timeout=60s
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - vim | low | low (visible before save) | high - any missing field |
| B - Python patch | high | low but brittle to file changes | low - scripting only |
