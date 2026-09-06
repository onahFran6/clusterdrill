# q106-28-chained-rbac-role-wrong-apigroup: reference solution

Doc: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole

```sh
kubectl patch role deploy-reader \
  -n q106-28-chained-rbac-role-wrong-apigroup \
  --type=json \
  -p '[{"op": "replace", "path": "/rules/0/apiGroups", "value": ["apps"]}]'
```
