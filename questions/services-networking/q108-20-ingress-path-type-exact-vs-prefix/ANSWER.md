# q108-20: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types

```sh
kubectl patch ingress diagnostics-ingress -n q108-20-ingress-path-type-exact-vs-prefix --type json -p '
[
  {"op": "replace", "path": "/spec/rules/0/http/paths/0/pathType", "value": "Exact"},
  {"op": "replace", "path": "/spec/rules/0/http/paths/1/pathType", "value": "Prefix"}
]'
```
