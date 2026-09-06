# q106-38-networkpolicy-allow-podselector: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/#networkpolicy-resource

```sh
kubectl apply -n q106-38-networkpolicy-allow-podselector -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: billing-db-allow
spec:
  podSelector:
    matchLabels:
      app: billing-db
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: billing-worker
EOF
```
