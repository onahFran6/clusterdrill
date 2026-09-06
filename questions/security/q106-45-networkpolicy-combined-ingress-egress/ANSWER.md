# q106-45-networkpolicy-combined-ingress-egress: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/#behavior-of-to-and-from-selectors

```sh
kubectl apply -n q106-45-networkpolicy-combined-ingress-egress -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: payments-api-policy
spec:
  podSelector:
    matchLabels:
      app: payments-api
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: api-gateway
      ports:
        - protocol: TCP
          port: 80
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: ledger-db
      ports:
        - protocol: TCP
          port: 5432
    - ports:
        - protocol: UDP
          port: 53
EOF
```
