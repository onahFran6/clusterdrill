# q108-40-service-add-second-selector-key-fix: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service

```sh
kubectl patch service payment-worker-svc -n q108-40-service-add-second-selector-key-fix \
  --type merge -p '{"spec":{"selector":{"app":"payment-worker","tier":"backend"}}}'
```
