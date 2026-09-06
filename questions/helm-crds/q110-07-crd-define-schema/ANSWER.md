# q110-07: reference solution

Doc: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/

```sh
kubectl apply -f - <<'EOF'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: coffeeorders.snacks.clusterdrill.io
  labels:
    clusterdrill-question: q110-07-crd-define-schema
spec:
  group: snacks.clusterdrill.io
  scope: Namespaced
  names:
    plural: coffeeorders
    singular: coffeeorder
    kind: CoffeeOrder
    listKind: CoffeeOrderList
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              required:
                - size
              properties:
                size:
                  type: string
EOF
```
