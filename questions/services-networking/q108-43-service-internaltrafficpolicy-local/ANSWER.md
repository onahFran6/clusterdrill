# q108-43-service-internaltrafficpolicy-local: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service-traffic-policy/

```sh
kubectl patch service metrics-sidecar-svc -n q108-43-service-internaltrafficpolicy-local \
  --type merge -p '{"spec":{"internalTrafficPolicy":"Local"}}'
```
