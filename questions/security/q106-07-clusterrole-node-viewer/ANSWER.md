# q106-07: reference solution

Doc: https://kubernetes.io/docs/reference/access-authn-authz/rbac/

```sh
kubectl create clusterrole q106-07-node-viewer \
  --verb=get --verb=list --verb=watch \
  --resource=nodes

kubectl label clusterrole q106-07-node-viewer \
  clusterdrill-question=q106-07-clusterrole-node-viewer
```
