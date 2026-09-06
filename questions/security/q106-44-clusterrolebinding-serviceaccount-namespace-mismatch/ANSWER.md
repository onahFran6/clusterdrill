# q106-44-clusterrolebinding-serviceaccount-namespace-mismatch: reference solution

Doc: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#referring-to-subjects

```sh
kubectl patch clusterrolebinding q106-44-deployer-binding --type=json -p '
[
  {
    "op": "replace",
    "path": "/subjects/0/namespace",
    "value": "q106-44-clusterrolebinding-serviceaccount-namespace-mismatch"
  }
]
'
```
