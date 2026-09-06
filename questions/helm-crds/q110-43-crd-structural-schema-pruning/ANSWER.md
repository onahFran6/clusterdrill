# q110-43-crd-structural-schema-pruning: reference solution

Doc: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#pruning-versus-preserving-unknown-fields

```sh
kubectl patch crd profiles.people.clusterdrill.io \
  --type json \
  -p '[{"op":"add","path":"/spec/versions/0/schema/openAPIV3Schema/properties/spec/properties/timezone","value":{"type":"string"}}]'

kubectl patch profile alice -n q110-43-crd-structural-schema-pruning \
  --type merge -p '{"spec":{"timezone":"America/New_York"}}'
```
