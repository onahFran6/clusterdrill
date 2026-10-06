# q116-01-exact-or-prefix: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types

```sh
QUESTION_ID="q116-01-exact-or-prefix"

kubectl -n "$QUESTION_ID" create ingress meteor --class=nginx \
  --rule="meteor.local/docs=docs-svc:80" \
  --rule="meteor.local/*=home-svc:80"
```
