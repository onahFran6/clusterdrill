# q106-20: reference solution

Doc: https://kubernetes.io/docs/reference/access-authn-authz/rbac/

```sh
kubectl delete rolebinding web-frontend-all-secrets -n q106-20-serviceaccount-no-secret-access
kubectl delete role all-secrets-reader -n q106-20-serviceaccount-no-secret-access
```
