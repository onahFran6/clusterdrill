# q108-50-networkpolicy-ipblock-peer-exclusivity-fix: reference solution

Doc: https://kubernetes.io/docs/reference/kubernetes-api/policy-resources/network-policy-v1/#NetworkPolicyPeer

```sh
cat >~/practice-work/q108-50-networkpolicy-ipblock-peer-exclusivity-fix/netpol.yaml <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: partner-gateway-allow-ingress
spec:
  podSelector:
    matchLabels:
      app: partner-gateway
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              role: internal-caller
        - ipBlock:
            cidr: 203.0.113.0/24
        - podSelector:
            matchLabels:
              role: metrics-scraper
          namespaceSelector:
            matchLabels:
              team: observability
      ports:
        - protocol: TCP
          port: 443
EOF

kubectl apply -n q108-50-networkpolicy-ipblock-peer-exclusivity-fix \
  -f ~/practice-work/q108-50-networkpolicy-ipblock-peer-exclusivity-fix/netpol.yaml
```
