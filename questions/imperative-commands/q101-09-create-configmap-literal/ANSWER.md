# q101-09: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create_configmap/

```sh
kubectl create configmap app-config \
  --from-literal=LOG_LEVEL=info \
  --from-literal=MAX_CONNECTIONS=100 \
  -n q101-09-create-configmap-literal
```
