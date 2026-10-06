# q114-02: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes

```sh
NS=q114-02-pending-access-mode

kubectl describe pvc amazon-pvc -n "$NS" | tail -5   # waiting for a volume to be created or bound
kubectl get pv q114-02-pv   # Available, ReadWriteOnce, 2Gi - plenty of room, but RWO != RWX

# accessModes is immutable once set, so the claim must be replaced, not patched.
kubectl get pvc amazon-pvc -n "$NS" -o json \
  | jq '.spec.accessModes = ["ReadWriteOnce"]' \
  | kubectl replace --force -f -

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/amazon-pvc -n "$NS" --timeout=60s
```

A claim's `accessModes` can't be edited after creation, hence `replace --force` (delete +
recreate) instead of `kubectl patch`. `ReadWriteOnce` means one **node** can mount it read-write,
which this single-pod claim never needed `ReadWriteMany` for in the first place.
