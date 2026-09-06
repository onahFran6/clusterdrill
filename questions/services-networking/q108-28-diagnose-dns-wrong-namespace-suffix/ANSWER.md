# q108-28-diagnose-dns-wrong-namespace-suffix: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#services

```sh
QUESTION_ID="q108-28-diagnose-dns-wrong-namespace-suffix"
FRONTEND_NS="${QUESTION_ID}-frontend"
BACKEND_NS="${QUESTION_ID}-backend"

kubectl set env deployment/web-ui -n "$FRONTEND_NS" \
  ORDERS_URL="http://orders-svc.${BACKEND_NS}.svc.cluster.local:8080/"

kubectl rollout status deployment/web-ui -n "$FRONTEND_NS" --timeout=90s
```
