# q106-35-secret-from-literal-two-keys: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/secret/#creating-a-secret-using-kubectl

```sh
kubectl create secret generic api-keys \
  --from-literal=PRIMARY_KEY=primary-key-123 \
  --from-literal=SECONDARY_KEY=backup-key-124 \
  -n q106-35-secret-from-literal-two-keys
```
