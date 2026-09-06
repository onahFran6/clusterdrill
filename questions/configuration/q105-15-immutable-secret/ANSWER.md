# q105-15: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/secret/#secret-immutable

```sh
kubectl patch secret signing-key -n q105-15-immutable-secret \
  --type=merge -p '{"immutable": true}'
```
