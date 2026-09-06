# q110-20: reference solution

Doc: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#subresources

```sh
kubectl patch backupjob nightly-backup -n q110-20-crd-status-subresource \
  --subresource=status --type=merge -p '{"status":{"phase":"Completed"}}'
```
