# q104-03: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout_undo/

```sh
kubectl rollout undo deployment/search -n q104-03-rollout-undo-previous

kubectl rollout status deployment/search -n q104-03-rollout-undo-previous --timeout=60s
```
