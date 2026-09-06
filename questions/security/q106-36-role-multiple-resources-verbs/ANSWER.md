# q106-36-role-multiple-resources-verbs: reference solution

Doc: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole

```sh
kubectl apply -n q106-36-role-multiple-resources-verbs -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: log-viewer-role
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get"]
EOF

kubectl create rolebinding log-viewer-binding \
  --role=log-viewer-role \
  --serviceaccount=q106-36-role-multiple-resources-verbs:log-viewer \
  -n q106-36-role-multiple-resources-verbs
```
