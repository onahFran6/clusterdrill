# q108-52-networkpolicy-same-namespace-only-ingress: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/

```sh
kubectl apply -n q108-52-networkpolicy-same-namespace-only-ingress -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: internal-api-allow-same-namespace
spec:
  podSelector:
    matchLabels:
      app: internal-api
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector: {}
EOF
```

An ingress peer entry with only `podSelector: {}` and no `namespaceSelector` matches every pod in
the NetworkPolicy's own namespace - never a pod in any other namespace, regardless of that
namespace's labels. That's the opposite shape from `q108-16`'s peer entry, which adds a
`namespaceSelector` specifically to reach across namespace boundaries.
