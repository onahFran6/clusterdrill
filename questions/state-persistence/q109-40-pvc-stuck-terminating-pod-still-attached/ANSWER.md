# q109-40-pvc-stuck-terminating-pod-still-attached: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#storage-object-in-use-protection

```sh
kubectl delete pod session-worker -n q109-40-pvc-stuck-terminating-pod-still-attached --wait=true
```

Deleting the Pod removes the reference blocking the `kubernetes.io/pvc-protection` finalizer,
so the already-pending PVC deletion completes on its own.
