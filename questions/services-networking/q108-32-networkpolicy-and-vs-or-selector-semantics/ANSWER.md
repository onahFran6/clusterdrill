# q108-32-networkpolicy-and-vs-or-selector-semantics: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/#behavior-of-to-and-from-selectors

```sh
kubectl apply -n q108-32-networkpolicy-and-vs-or-selector-semantics -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-trusted-platform-clients
spec:
  podSelector:
    matchLabels:
      app: payment-api
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              role: trusted-client
          namespaceSelector:
            matchLabels:
              team: platform
      ports:
        - protocol: TCP
          port: 8443
EOF
```
