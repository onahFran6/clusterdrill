# q103-28: reference solution

Doc: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#resources-that-support-set-based-requirements

```sh
kubectl get pods -n q103-28-promote-worker-pods-by-label \
  -l 'tier=worker,env in (staging,prod)'

kubectl label pods -n q103-28-promote-worker-pods-by-label \
  -l 'tier=worker,env in (staging,prod)' promote=true
```
