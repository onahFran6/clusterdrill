# q103-33: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-template

```sh
NS=q103-33-job-invalid-restartpolicy-fix
MANIFEST="$HOME/practice-work/$NS/broken-once.yaml"

sed -i.bak 's/restartPolicy: Always/restartPolicy: Never/' "$MANIFEST"

kubectl apply -f "$MANIFEST"

kubectl wait --for=condition=Complete job/broken-once -n "$NS" --timeout=60s
```
