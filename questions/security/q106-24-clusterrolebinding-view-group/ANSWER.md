# q106-24-clusterrolebinding-view-group: reference solution

Doc: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles

```sh
kubectl create clusterrolebinding auditor-view-binding \
  --clusterrole=view \
  --serviceaccount=q106-24-clusterrolebinding-view-group:auditor

kubectl label clusterrolebinding auditor-view-binding \
  clusterdrill-question=q106-24-clusterrolebinding-view-group
```
