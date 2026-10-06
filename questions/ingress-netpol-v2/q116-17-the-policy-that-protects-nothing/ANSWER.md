# q116-17-the-policy-that-protects-nothing: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/

```sh
QUESTION_ID="q116-17-the-policy-that-protects-nothing"
WRONG_NS="${QUESTION_ID}-wrong"

kubectl delete networkpolicy web-only-frontend -n "$WRONG_NS"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-only-frontend
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes: ["Ingress"]
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
EOF
```
