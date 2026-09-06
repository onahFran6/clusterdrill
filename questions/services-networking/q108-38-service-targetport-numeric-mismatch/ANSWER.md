# q108-38-service-targetport-numeric-mismatch: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#field-service-v1-core

```sh
kubectl patch service media-worker-svc -n q108-38-service-targetport-numeric-mismatch \
  --type json -p '[{"op":"replace","path":"/spec/ports/0/targetPort","value":8080}]'
```
