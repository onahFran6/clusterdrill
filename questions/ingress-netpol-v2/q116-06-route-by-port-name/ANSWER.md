# q116-06-route-by-port-name: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#backends

```sh
QUESTION_ID="q116-06-route-by-port-name"

kubectl -n "$QUESTION_ID" patch svc app-svc --type=json \
  -p='[{"op":"add","path":"/spec/ports/0/name","value":"web"}]'

kubectl -n "$QUESTION_ID" create ingress cosmos --class=nginx \
  --rule="cosmos.local/healthz=health-svc:80" \
  --rule="cosmos.local/*=app-svc:web"
```
