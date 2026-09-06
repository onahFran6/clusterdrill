# q108-16: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/

```sh
kubectl apply -n q108-16-networkpolicy-namespace-selector -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: shared-cache-allow-platform-ns
spec:
  podSelector:
    matchLabels:
      app: shared-cache
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              team: platform
      ports:
        - protocol: TCP
          port: 6379
EOF
```
