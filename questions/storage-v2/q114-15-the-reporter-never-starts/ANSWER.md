# q114-15: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/

```sh
NS=q114-15-the-reporter-never-starts

kubectl describe pod -n "$NS" -l app=reporter | tail -n 3   # persistentvolumeclaim "report" not found
kubectl describe pvc reports -n "$NS" | tail -n 3           # storageclass "q114-15-fast-ssd" not found

# storageClassName is immutable - the claim must be replaced, not patched.
kubectl get pvc reports -n "$NS" -o json | jq 'del(.spec.storageClassName)' | kubectl replace --force -f -

kubectl patch deployment reporter -n "$NS" --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/volumes/0/persistentVolumeClaim/claimName","value":"reports"}]'

kubectl rollout status deployment/reporter -n "$NS" --timeout=60s
```

A claim with a non-existent class waits forever - it never falls back to the default. Both faults
surface as the same symptom (`Pending`), which is why you read events on both the Pod and the
PVC. Deleting `storageClassName` from the claim lets the `DefaultStorageClass` admission plugin
fill it back in with the cluster's real default the moment it's replaced.
