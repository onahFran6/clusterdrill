# q110-47-crd-switch-storage-version: reference solution

Doc: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/

```sh
kubectl patch crd snapshots.storagepolicy.clusterdrill.io \
  --type json \
  -p '[
    {"op":"replace","path":"/spec/versions/0/storage","value":false},
    {"op":"replace","path":"/spec/versions/1/storage","value":true}
  ]'
```
