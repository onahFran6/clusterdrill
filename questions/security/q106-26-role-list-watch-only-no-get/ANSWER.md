# q106-26-role-list-watch-only-no-get: reference solution

Doc: https://kubernetes.io/docs/reference/access-authn-authz/rbac/

```sh
kubectl create role pod-watcher \
  --verb=list --verb=watch \
  --resource=pods \
  -n q106-26-role-list-watch-only-no-get

kubectl create rolebinding dashboard-binding \
  --role=pod-watcher \
  --serviceaccount=q106-26-role-list-watch-only-no-get:dashboard-sa \
  -n q106-26-role-list-watch-only-no-get
```
