# q105-03: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create_configmap/

```sh
kubectl create configmap worker-settings \
  --from-env-file=$HOME/practice-work/q105-03-configmap-from-env-file/q105-03.env \
  -n q105-03-configmap-from-env-file
```
