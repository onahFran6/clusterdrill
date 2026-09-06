# q108-15: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/

```sh
kubectl apply -n q108-15-networkpolicy-allow-egress-to-pods -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: report-generator-restrict-egress
spec:
  podSelector:
    matchLabels:
      app: report-generator
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: metrics-store
      ports:
        - protocol: TCP
          port: 9090
EOF
```
