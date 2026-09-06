# q103-50: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#completion-mode

```sh
NS=q103-50-job-indexed-completion-with-nodeaffinity-required
MANIFEST="$HOME/practice-work/$NS/sharded-worker.yaml"

TARGET_NODE="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')"

python3 - "$MANIFEST" "$TARGET_NODE" <<'PY'
import sys
path, node = sys.argv[1], sys.argv[2]
with open(path) as f:
    text = f.read()
text = text.replace("spec:\n  completions:", "spec:\n  completionMode: Indexed\n  completions:", 1)
affinity = f"""      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: kubernetes.io/hostname
                    operator: In
                    values:
                      - {node}
"""
text = text.replace("      restartPolicy: Never", affinity + "      restartPolicy: Never", 1)
with open(path, "w") as f:
    f.write(text)
PY

kubectl apply -f "$MANIFEST"

kubectl wait --for=condition=Complete job/sharded-worker -n "$NS" --timeout=90s
```
