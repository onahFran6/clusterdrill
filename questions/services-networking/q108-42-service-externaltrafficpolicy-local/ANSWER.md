# q108-42-service-externaltrafficpolicy-local: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#preserving-the-client-source-ip

```sh
kubectl patch service edge-gateway-svc -n q108-42-service-externaltrafficpolicy-local \
  --type merge -p '{"spec":{"externalTrafficPolicy":"Local"}}'
```
