# q113-15-default-deny-allow-one-path: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/#default-deny-all-ingress-traffic

```sh
QUESTION_ID=q113-15-default-deny-allow-one-path

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}
  policyTypes: ["Ingress"]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend
spec:
  podSelector:
    matchLabels: { app: backend }
  policyTypes: ["Ingress"]
  ingress:
    - from:
        - podSelector:
            matchLabels: { app: frontend }
      ports:
        - { protocol: TCP, port: 80 }
EOF
```

An empty `podSelector` selects every pod in the namespace. A policy with `policyTypes: [Ingress]`
and no `ingress` rules allows nothing in at all - that's `default-deny`'s whole job. NetworkPolicy
rules are purely additive: `allow-frontend` never has to repeat the deny, it only opens the one
path `default-deny` already closed. `intruder` stays unable to reach `backend` because no policy
ever names it.
