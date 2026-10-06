# q114-16: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#storage-object-in-use-protection

```sh
NS=q114-16-deleted-while-in-use

kubectl get pvc data -n "$NS" -o jsonpath='{.status.phase} {.metadata.deletionTimestamp} {.metadata.finalizers}'; echo
kubectl get pvc data -n "$NS"   # STATUS Terminating; finalizer kubernetes.io/pvc-protection

PV="$(kubectl get pvc data -n "$NS" -o jsonpath='{.spec.volumeName}')"
kubectl patch pv "$PV" -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
kubectl delete pod app -n "$NS" --force --grace-period=0

sleep 5
kubectl get pvc data -n "$NS" 2>&1   # gone
kubectl get pv "$PV" -o jsonpath='{.spec.persistentVolumeReclaimPolicy} {.status.phase}'; echo   # Retain Released
```

The `pvc-protection` finalizer delays deletion until no Pod uses the claim - it doesn't cancel
it. Dynamic PVs default to `Delete`, so without the patch the data would have been removed the
moment the Pod went. To reuse this now-`Released` PV, follow q114-05's pattern: clear its stale
`claimRef`.
