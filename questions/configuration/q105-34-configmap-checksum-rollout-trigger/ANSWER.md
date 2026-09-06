# q105-34-configmap-checksum-rollout-trigger: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment

```sh
NS=q105-34-configmap-checksum-rollout-trigger

CHECKSUM="$(kubectl get configmap app-config -n "$NS" -o jsonpath='{.data}' | sha256sum | awk '{print $1}')"

kubectl patch deployment worker -n "$NS" --type strategic -p "
spec:
  template:
    metadata:
      annotations:
        checksum/config: \"$CHECKSUM\"
"

kubectl rollout status deployment/worker -n "$NS" --timeout=120s
```
