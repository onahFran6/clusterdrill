# q106-42-networkpolicy-egress-allow-dns-and-target: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource

A common gotcha: restricting a Pod's egress also blocks its DNS lookups unless port 53 is
explicitly allowed alongside the intended destination.

```sh
kubectl apply -n q106-42-networkpolicy-egress-allow-dns-and-target -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: report-generator-egress
spec:
  podSelector:
    matchLabels:
      app: report-generator
  policyTypes:
    - Egress
  egress:
    - ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
    - to:
        - podSelector:
            matchLabels:
              app: data-store
      ports:
        - protocol: TCP
          port: 80
EOF
```
