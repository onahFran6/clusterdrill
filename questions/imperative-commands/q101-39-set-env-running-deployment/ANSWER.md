# q101-39-set-env-running-deployment: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#set-env

```sh
kubectl set env deployment/report-worker FEATURE_FLAG=beta \
  -n q101-39-set-env-running-deployment

kubectl rollout status deployment/report-worker \
  -n q101-39-set-env-running-deployment --timeout=60s
```
