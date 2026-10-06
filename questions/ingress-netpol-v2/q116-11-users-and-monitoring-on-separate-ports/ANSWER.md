# q116-11-users-and-monitoring-on-separate-ports: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/

```sh
QUESTION_ID="q116-11-users-and-monitoring-on-separate-ports"
# Never hardcode a generic "monitoring" namespace name - resolve the real,
# live one this question actually seeded.
MONITORING_NS="${QUESTION_ID}-monitoring"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-access
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes: ["Ingress"]
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
          podSelector:
            matchLabels:
              app.kubernetes.io/name: ingress-nginx
      ports:
        - protocol: TCP
          port: http
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: $MONITORING_NS
      ports:
        - protocol: TCP
          port: metrics
EOF
```
