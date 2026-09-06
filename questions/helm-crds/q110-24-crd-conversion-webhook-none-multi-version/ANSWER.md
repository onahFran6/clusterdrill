# q110-24-crd-conversion-webhook-none-multi-version: reference solution

Doc: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/

```sh
kubectl patch crd reports.analytics.clusterdrill.io --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/versions/-",
    "value": {
      "name": "v1",
      "served": true,
      "storage": false,
      "schema": {
        "openAPIV3Schema": {
          "type": "object",
          "properties": {
            "spec": {
              "type": "object",
              "required": ["title"],
              "properties": {
                "title": {
                  "type": "string"
                }
              }
            }
          }
        }
      }
    }
  }
]'

kubectl wait --for=condition=Established crd/reports.analytics.clusterdrill.io --timeout=60s
```
