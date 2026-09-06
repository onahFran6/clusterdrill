# q110-45-crd-ownerreference-cascade-gc: reference solution

Doc: https://kubernetes.io/docs/concepts/architecture/garbage-collection/#owners-dependents

```sh
NS=q110-45-crd-ownerreference-cascade-gc

PARENT_UID="$(kubectl get backupset nightly -n "$NS" -o jsonpath='{.metadata.uid}')"

kubectl patch configmap nightly-manifest -n "$NS" \
  --type merge \
  -p "{\"metadata\":{\"ownerReferences\":[{\"apiVersion\":\"ops.clusterdrill.io/v1\",\"kind\":\"BackupSet\",\"name\":\"nightly\",\"uid\":\"$PARENT_UID\"}]}}"
```
