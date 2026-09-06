# q110-49-crd-json-patch-array-append: reference solution

Doc: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/update-api-object-kubectl-patch/

```sh
kubectl patch playlist mix1 -n q110-49-crd-json-patch-array-append \
  --type json \
  -p '[{"op":"add","path":"/spec/tracks/-","value":"song-c"}]'
```
