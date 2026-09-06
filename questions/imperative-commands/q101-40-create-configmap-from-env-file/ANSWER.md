# q101-40-create-configmap-from-env-file: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#create-a-configmap-from-generators

```sh
kubectl create configmap service-env \
  -n q101-40-create-configmap-from-env-file \
  --from-env-file="$HOME/practice-work/q101-40-create-configmap-from-env-file/service.env"
```
