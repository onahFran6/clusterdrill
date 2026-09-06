# q108-19: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#how-services-work

```sh
kubectl patch service notification-worker-svc -n q108-19-fix-broken-service-selector --type merge -p '
{
  "spec": {
    "selector": {
      "app": "notification-worker"
    }
  }
}'

kubectl wait --for=jsonpath='{.subsets[0].addresses[0].ip}' \
  endpoints/notification-worker-svc -n q108-19-fix-broken-service-selector --timeout=60s
```
