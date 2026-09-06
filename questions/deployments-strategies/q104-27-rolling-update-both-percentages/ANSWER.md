# q104-27-rolling-update-both-percentages: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#max-unavailable

```sh
kubectl patch deployment catalog-svc \
  -n q104-27-rolling-update-both-percentages \
  --type merge \
  -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":"50%","maxUnavailable":"25%"}}}}'

kubectl rollout status deployment/catalog-svc \
  -n q104-27-rolling-update-both-percentages --timeout=60s
```
