# q110-28-crd-finalizer-stuck-deletion: reference solution

Doc: https://kubernetes.io/docs/concepts/overview/working-with-objects/finalizers/

```sh
kubectl patch archive cold-store-1 -n q110-28-crd-finalizer-stuck-deletion \
  --type=json -p '[{"op":"remove","path":"/metadata/finalizers"}]'
```
