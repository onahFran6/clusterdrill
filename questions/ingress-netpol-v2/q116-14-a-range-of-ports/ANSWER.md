# q116-14-a-range-of-ports: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/#targeting-a-range-of-ports

```sh
QUESTION_ID="q116-14-a-range-of-ports"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: game-ports
spec:
  podSelector:
    matchLabels:
      app: game
  policyTypes: ["Ingress"]
  ingress:
    - from:
        - podSelector:
            matchLabels:
              role: player
      ports:
        - protocol: TCP
          port: 7000
          endPort: 7100
EOF
```
