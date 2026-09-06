# q106-08: reference solution

Doc: https://kubernetes.io/docs/reference/access-authn-authz/rbac/

```sh
kubectl create clusterrolebinding q106-08-fleet-inspector-binding \
  --clusterrole=q106-08-namespace-viewer \
  --serviceaccount=q106-08-clusterrolebinding-bind-sa:fleet-inspector

kubectl label clusterrolebinding q106-08-fleet-inspector-binding \
  clusterdrill-question=q106-08-clusterrolebinding-bind-sa
```
