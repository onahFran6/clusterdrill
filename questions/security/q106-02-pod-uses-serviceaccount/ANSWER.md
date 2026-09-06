# q106-02: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/

```sh
kubectl run report-job --image=busybox:1.36 \
  -n q106-02-pod-uses-serviceaccount \
  --overrides='{"spec":{"serviceAccountName":"report-runner"}}' \
  -- sleep 3600
```
