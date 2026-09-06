# q106-04: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/

```sh
kubectl patch serviceaccount metrics-reader -n q106-04-disable-automount-sa-level \
  -p '{"automountServiceAccountToken": false}'
```
