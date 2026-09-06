# q110-10: reference solution

Doc: https://kubernetes.io/docs/reference/kubernetes-api/extend-resources/custom-resource-definition-v1/

```sh
kubectl apply -f - <<'EOF'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: menuitems.diner.clusterdrill.io
  labels:
    clusterdrill-question: q110-10-crd-scope-namespaced
spec:
  group: diner.clusterdrill.io
  scope: Namespaced
  names:
    plural: menuitems
    singular: menuitem
    kind: MenuItem
    listKind: MenuItemList
    shortNames:
      - mi
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
                - dish
              properties:
                dish:
                  type: string
EOF

kubectl wait --for=condition=Established crd/menuitems.diner.clusterdrill.io --timeout=60s

kubectl apply -n q110-10-crd-scope-namespaced -f - <<'EOF'
apiVersion: diner.clusterdrill.io/v1
kind: MenuItem
metadata:
  name: special-1
spec:
  dish: ramen
EOF
```
