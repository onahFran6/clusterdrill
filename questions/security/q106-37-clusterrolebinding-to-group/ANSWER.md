# q106-37-clusterrolebinding-to-group: reference solution

Doc: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding

```sh
kubectl create clusterrolebinding q106-37-namespace-viewer-binding \
  --clusterrole=q106-37-namespace-viewer \
  --group=platform-auditors

kubectl label clusterrolebinding q106-37-namespace-viewer-binding \
  clusterdrill-question=q106-37-clusterrolebinding-to-group
```
