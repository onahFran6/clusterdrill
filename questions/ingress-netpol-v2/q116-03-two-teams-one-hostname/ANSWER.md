# q116-03-two-teams-one-hostname: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#name-based-virtual-hosting

```sh
QUESTION_ID="q116-03-two-teams-one-hostname"
BLOG_NS="${QUESTION_ID}-blog"

kubectl -n "$QUESTION_ID" create ingress shop --class=nginx \
  --rule="nebula.local/shop*=shop-svc:80"

kubectl -n "$BLOG_NS" create ingress blog --class=nginx \
  --rule="nebula.local/blog*=blog-svc:80"
```
