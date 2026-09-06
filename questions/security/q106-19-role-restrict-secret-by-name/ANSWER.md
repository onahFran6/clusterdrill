# q106-19: reference solution

Doc: https://kubernetes.io/docs/reference/access-authn-authz/rbac/

```sh
kubectl apply -n q106-19-role-restrict-secret-by-name -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: db-credentials-reader
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames: ["db-credentials"]
    verbs: ["get"]
EOF

kubectl create rolebinding report-service-binding \
  --role=db-credentials-reader \
  --serviceaccount=q106-19-role-restrict-secret-by-name:report-service \
  -n q106-19-role-restrict-secret-by-name
```
