# q116-07-longest-prefix-wins: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#multiple-matches

```sh
QUESTION_ID="q116-07-longest-prefix-wins"

kubectl -n "$QUESTION_ID" create ingress zenith --class=nginx \
  --rule="zenith.local/api*=v1-svc:80" \
  --rule="zenith.local/api/v2*=v2-svc:80"
```
