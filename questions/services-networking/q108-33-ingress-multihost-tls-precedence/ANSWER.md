# q108-33-ingress-multihost-tls-precedence: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#tls

```sh
NS=q108-33-ingress-multihost-tls-precedence

# Confirm the bug: spec.tls's second entry (api.shop.example.local) still
# names shop-web-tls, copy-pasted from the first entry.
kubectl get ingress shop-ingress -n "$NS" -o jsonpath='{.spec.tls}'

# Fix only the TLS secretName mapping - leave spec.rules untouched.
kubectl patch ingress shop-ingress -n "$NS" --type='json' -p='[
  {"op": "replace", "path": "/spec/tls/1/secretName", "value": "shop-api-tls"}
]'

# Verify both hosts now serve their own matching certificate.
kubectl get ingress shop-ingress -n "$NS" -o jsonpath='{.spec.tls}'
```
