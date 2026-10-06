# q116-19-neighbours-and-the-ingress-only: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/#behavior-of-to-and-from-selectors

```sh
QUESTION_ID="q116-19-neighbours-and-the-ingress-only"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: shop-sources
spec:
  podSelector:
    matchLabels:
      app: shop
  policyTypes: ["Ingress"]
  ingress:
    - from:
        - podSelector: {}
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
          podSelector:
            matchLabels:
              app.kubernetes.io/name: ingress-nginx
EOF
```
