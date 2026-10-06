# q116-10-canary-for-testers-only: reference solution

Doc: https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#canary

```sh
QUESTION_ID="q116-10-canary-for-testers-only"

kubectl -n "$QUESTION_ID" create ingress comet-canary --class=nginx \
  --rule="comet.local/*=canary-svc:80" \
  --annotation=nginx.ingress.kubernetes.io/canary=true \
  --annotation=nginx.ingress.kubernetes.io/canary-by-header=X-Canary
```
