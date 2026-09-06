# q108-29-networkpolicy-conflicting-rules-egress-dns: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-dns-problem

```sh
kubectl apply -n q108-29-networkpolicy-conflicting-rules-egress-dns -f - <<EOF
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
    - to:
        - podSelector:
            matchLabels:
              app: internal-api
      ports:
        - protocol: TCP
          port: 8080
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
EOF
```
