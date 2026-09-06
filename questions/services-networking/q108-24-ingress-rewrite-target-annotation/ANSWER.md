# q108-24-ingress-rewrite-target-annotation: reference solution

Doc: https://kubernetes.github.io/ingress-nginx/examples/rewrite/

```sh
kubectl annotate ingress shop-ingress -n q108-24-ingress-rewrite-target-annotation \
  nginx.ingress.kubernetes.io/rewrite-target=/ --overwrite

kubectl patch ingress shop-ingress -n q108-24-ingress-rewrite-target-annotation --type json -p '
[
  {"op": "replace", "path": "/spec/rules/0/http/paths/0/path", "value": "/api(/|$)(.*)"},
  {"op": "replace", "path": "/spec/rules/0/http/paths/0/pathType", "value": "ImplementationSpecific"}
]'
```
