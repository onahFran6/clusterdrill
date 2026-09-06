# q108-45-ingress-tls-secretname-mismatch-fix: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#tls

```sh
kubectl patch ingress secure-app-ingress -n q108-45-ingress-tls-secretname-mismatch-fix \
  --type json \
  -p '[{"op":"replace","path":"/spec/tls/0/secretName","value":"secure-app-tls"}]'
```
