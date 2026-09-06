# q103-20: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_label/

```sh
kubectl label pods -n q103-20-bulk-label-pods-by-selector -l tier=backend rollout=canary
```
