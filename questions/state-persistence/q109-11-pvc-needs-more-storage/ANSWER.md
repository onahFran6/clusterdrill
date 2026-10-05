# q109-11: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#resizing-a-persistent-volume-claim

```sh
NS=q109-11-pvc-needs-more-storage

kubectl patch pvc growing-claim -n "$NS" \
  -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}'
```
