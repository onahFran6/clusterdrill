# q110-17: reference solution

Doc: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/

```sh
kubectl apply -f - <<'EOF'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: datacenters.infra.clusterdrill.io
  labels:
    clusterdrill-question: q110-17-crd-cluster-scoped
spec:
  group: infra.clusterdrill.io
  scope: Cluster
  names:
    plural: datacenters
    singular: datacenter
    kind: DataCenter
    listKind: DataCenterList
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
                - region
              properties:
                region:
                  type: string
EOF

kubectl wait --for=condition=Established crd/datacenters.infra.clusterdrill.io --timeout=60s

kubectl apply -f - <<'EOF'
apiVersion: infra.clusterdrill.io/v1
kind: DataCenter
metadata:
  name: dc-east
spec:
  region: us-east-1
EOF
```
