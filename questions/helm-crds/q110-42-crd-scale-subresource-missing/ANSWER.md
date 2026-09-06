# q110-42-crd-scale-subresource-missing: reference solution

Doc: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#scale-subresource

```sh
kubectl patch crd workerpools.ops.clusterdrill.io \
  --type json \
  -p '[{"op":"add","path":"/spec/versions/0/subresources","value":{
    "scale": {
      "specReplicasPath": ".spec.replicas",
      "statusReplicasPath": ".status.replicas",
      "labelSelectorPath": ".status.selector"
    }
  }}]'

kubectl scale workerpool pool-a -n q110-42-crd-scale-subresource-missing --replicas=5
```
