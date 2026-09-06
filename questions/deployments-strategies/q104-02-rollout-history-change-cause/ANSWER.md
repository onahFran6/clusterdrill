# q104-02: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#checking-rollout-history-of-a-deployment

```sh
kubectl set image deployment/pricing pricing=nginx:1.25-alpine \
  -n q104-02-rollout-history-change-cause

kubectl annotate deployment/pricing \
  kubernetes.io/change-cause="update nginx to 1.25-alpine" \
  -n q104-02-rollout-history-change-cause --overwrite

kubectl rollout status deployment/pricing -n q104-02-rollout-history-change-cause --timeout=60s

kubectl rollout history deployment/pricing -n q104-02-rollout-history-change-cause
```
