# q108-06: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/

```sh
READY_COUNT=$(kubectl get endpointslice -n q108-06-inspect-endpointslices \
  -l kubernetes.io/service-name=order-api-svc \
  -o jsonpath='{range .items[*]}{range .endpoints[?(@.conditions.ready==true)]}{.addresses[*]}{"\n"}{end}{end}' \
  | grep -c .)

kubectl create configmap order-api-endpoint-report \
  -n q108-06-inspect-endpointslices \
  --from-literal=ready-count="$READY_COUNT"
```
