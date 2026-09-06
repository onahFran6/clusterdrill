# q110-36-crd-categories-field-kubectl-get-all: reference solution

Doc: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#categories

```sh
kubectl patch crd widgets.catalog.clusterdrill.io \
  --type json \
  -p '[{"op":"add","path":"/spec/names/categories","value":["all"]}]'
```
