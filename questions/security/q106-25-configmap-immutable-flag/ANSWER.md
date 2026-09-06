# q106-25-configmap-immutable-flag: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/configmap/#configmap-immutable

```sh
kubectl patch configmap app-config -n q106-25-configmap-immutable-flag \
  --type merge -p '{"immutable": true}'
```
