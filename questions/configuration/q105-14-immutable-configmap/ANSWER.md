# q105-14: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/configmap/#configmap-immutable

```sh
kubectl patch configmap release-info -n q105-14-immutable-configmap \
  --type=merge -p '{"immutable": true}'
```
