# q103-34: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination

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
