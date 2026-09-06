# q101-42-patch-deployment-rollout-strategy: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-update-deployment

```sh
kubectl patch deployment checkout-api \
  -n q101-42-patch-deployment-rollout-strategy \
  --type merge \
  -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0}}}}'
```
