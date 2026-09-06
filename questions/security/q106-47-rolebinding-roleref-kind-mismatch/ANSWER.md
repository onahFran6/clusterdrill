# q106-47-rolebinding-roleref-kind-mismatch: reference solution

Doc: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-binding-examples

`roleRef` is immutable on an existing RoleBinding - delete and recreate it.

```sh
kubectl delete rolebinding auditor-binding -n q106-47-rolebinding-roleref-kind-mismatch --wait=true

kubectl apply -n q106-47-rolebinding-roleref-kind-mismatch -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: auditor-binding
  labels:
    clusterdrill-question: q106-47-rolebinding-roleref-kind-mismatch
subjects:
  - kind: ServiceAccount
    name: auditor
    namespace: q106-47-rolebinding-roleref-kind-mismatch
roleRef:
  kind: Role
  name: q106-47-secret-reader
  apiGroup: rbac.authorization.k8s.io
EOF
```
