# q106-49-clusterrole-nonresourceurl-healthz: reference solution

Doc: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#referring-to-resources

```sh
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: q106-49-healthz-prober
  labels:
    clusterdrill-question: q106-49-clusterrole-nonresourceurl-healthz
rules:
  - nonResourceURLs: ["/healthz", "/healthz/*"]
    verbs: ["get"]
EOF

kubectl create clusterrolebinding q106-49-health-prober-binding \
  --clusterrole=q106-49-healthz-prober \
  --serviceaccount=q106-49-clusterrole-nonresourceurl-healthz:health-prober

kubectl label clusterrolebinding q106-49-health-prober-binding \
  clusterdrill-question=q106-49-clusterrole-nonresourceurl-healthz
```
