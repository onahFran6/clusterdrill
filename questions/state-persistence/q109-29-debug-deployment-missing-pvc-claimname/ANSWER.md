# q109-29-debug-deployment-missing-pvc-claimname: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/

```sh
NS=q109-29-debug-deployment-missing-pvc-claimname

kubectl patch deployment orders-api -n "$NS" --type=json -p='[
  {"op": "replace", "path": "/spec/template/spec/volumes/0/persistentVolumeClaim/claimName", "value": "orders-data"}
]'

kubectl rollout status deployment/orders-api -n "$NS" --timeout=60s
```
