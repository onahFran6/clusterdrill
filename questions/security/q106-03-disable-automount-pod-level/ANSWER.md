# q106-03: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/

```sh
kubectl get pod static-renderer -n q106-03-disable-automount-pod-level -o json \
  | jq '.spec.automountServiceAccountToken = false' \
  | kubectl replace --force -f -
```
