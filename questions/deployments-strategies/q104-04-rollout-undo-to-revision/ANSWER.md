# q104-04: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout_undo/

```sh
kubectl rollout undo deployment/billing --to-revision=1 -n q104-04-rollout-undo-to-revision

kubectl rollout status deployment/billing -n q104-04-rollout-undo-to-revision --timeout=60s
```
