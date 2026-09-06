# q107-33-rollout-history-change-cause: reference solution

Doc: https://kubernetes.io/docs/tasks/run-application/rolling-update-deployment/#checking-rollout-history-of-a-deployment

```sh
kubectl annotate deployment web-app -n q107-33-rollout-history-change-cause \
  kubernetes.io/change-cause="upgrade nginx to 1.25-alpine"

kubectl set image deployment/web-app web-app=nginx:1.25-alpine -n q107-33-rollout-history-change-cause

kubectl rollout status deployment/web-app -n q107-33-rollout-history-change-cause --timeout=60s

kubectl rollout history deployment/web-app -n q107-33-rollout-history-change-cause
```
