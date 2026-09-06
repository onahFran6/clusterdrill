# q108-36-fix-externalname-wrong-target: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#externalname

```sh
kubectl patch service legacy-api-svc -n q108-36-fix-externalname-wrong-target \
  --type merge -p '{"spec":{"externalName":"api.internal.example.com"}}'
```
