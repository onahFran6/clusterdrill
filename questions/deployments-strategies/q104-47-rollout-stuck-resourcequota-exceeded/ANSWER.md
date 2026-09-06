# q104-47-rollout-stuck-resourcequota-exceeded: reference solution

Doc: https://kubernetes.io/docs/concepts/policy/resource-quotas/#requests-vs-limits

```sh
kubectl set resources deployment/checkout-worker -c checkout-worker \
  --requests=cpu=200m --limits=cpu=200m \
  -n q104-47-rollout-stuck-resourcequota-exceeded

kubectl rollout status deployment/checkout-worker -n q104-47-rollout-stuck-resourcequota-exceeded --timeout=90s
```
