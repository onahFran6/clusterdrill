# q101-15: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_run/

```sh
kubectl run env-demo --image=busybox:1.36 \
  --env=APP_ENV=production \
  --env=RETRY_COUNT=3 \
  -n q101-15-run-pod-env-vars \
  -- sleep 3600
```
