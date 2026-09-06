# q103-38: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/

```sh
NS=q103-38-job-command-args-split-fix
MANIFEST="$HOME/practice-work/$NS/word-counter.yaml"

python3 - "$MANIFEST" <<'PY'
import sys
path = sys.argv[1]
with open(path) as f:
    text = f.read()
text = text.replace(
    'command: ["wc -l /etc/hostname"]',
    'command: ["wc"]\n      args: ["-l", "/etc/hostname"]',
)
with open(path, "w") as f:
    f.write(text)
PY

kubectl apply -f "$MANIFEST"

kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/word-counter -n "$NS" --timeout=60s
kubectl logs word-counter -n "$NS"
```
