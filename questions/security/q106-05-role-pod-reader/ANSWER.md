# q106-05: reference solution

Doc: https://kubernetes.io/docs/reference/access-authn-authz/rbac/

```sh
kubectl create role pod-reader \
  --verb=get --verb=list --verb=watch \
  --resource=pods \
  -n q106-05-role-pod-reader
```
