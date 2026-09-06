# q106-06: reference solution

Doc: https://kubernetes.io/docs/reference/access-authn-authz/rbac/

```sh
kubectl create rolebinding config-watcher-binding \
  --role=configmap-reader \
  --serviceaccount=q106-06-rolebinding-bind-sa-to-role:config-watcher \
  -n q106-06-rolebinding-bind-sa-to-role
```
