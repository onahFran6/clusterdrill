# q106-22-imagepullsecret-attach-to-serviceaccount: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#add-imagepullsecrets-to-a-service-account

```sh
kubectl patch serviceaccount builder -n q106-22-imagepullsecret-attach-to-serviceaccount \
  -p '{"imagePullSecrets": [{"name": "registry-creds"}]}'
```
