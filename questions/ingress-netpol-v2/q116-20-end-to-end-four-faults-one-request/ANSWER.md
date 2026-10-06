# q116-20-end-to-end-four-faults-one-request: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/

```sh
QUESTION_ID="q116-20-end-to-end-four-faults-one-request"
DATA_NS="${QUESTION_ID}-data"

# Fault 1: Ingress backend pointed at the container's own port (8080)
# instead of web-svc's real Service port (80).
kubectl patch ingress carina -n "$QUESTION_ID" --type=json \
  -p='[{"op":"replace","path":"/spec/rules/0/http/paths/0/backend/service/port/number","value":80}]'

# Fault 2: deny-all blocks the ingress-nginx controller from ever reaching
# web on its real container port (8080).
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-from-ingress
spec:
  podSelector:
    matchLabels:
      app: web
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
          port: 8080
EOF

# Fault 3: web-to-quotes grants no DNS egress at all, so
# quotes-svc.$DATA_NS can't even resolve.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
spec:
  podSelector: {}
  policyTypes: ["Egress"]
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
EOF

# Fault 4: the other team's quotes-from-carina policy (never edited) only
# admits namespaces labeled team=carina - this namespace never got that
# label.
kubectl label namespace "$QUESTION_ID" team=carina
```
