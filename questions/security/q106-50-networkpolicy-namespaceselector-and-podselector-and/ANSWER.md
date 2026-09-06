# q106-50-networkpolicy-namespaceselector-and-podselector-and: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/#behavior-of-to-and-from-selectors

```sh
kubectl apply -n q106-50-networkpolicy-namespaceselector-and-podselector-and -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: secrets-vault-allow
spec:
  podSelector:
    matchLabels:
      app: secrets-vault
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              team: platform
          podSelector:
            matchLabels:
              role: trusted-caller
EOF
```
