# q116-16-selecting-with-expressions: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/#behavior-of-to-and-from-selectors

```sh
QUESTION_ID="q116-16-selecting-with-expressions"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ledger-callers
spec:
  podSelector:
    matchLabels:
      app: ledger
  policyTypes: ["Ingress"]
  ingress:
    - from:
        - podSelector:
            matchExpressions:
              - key: team
                operator: In
                values: ["payments", "billing"]
              - key: env
                operator: NotIn
                values: ["dev"]
              - key: audited
                operator: Exists
EOF
```
