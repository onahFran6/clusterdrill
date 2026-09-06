# q104-07: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout_pause/

```sh
kubectl rollout pause deployment/notifications -n q104-07-pause-rollout-mid-update

kubectl set image deployment/notifications notifications=nginx:1.25-alpine \
  -n q104-07-pause-rollout-mid-update
```
