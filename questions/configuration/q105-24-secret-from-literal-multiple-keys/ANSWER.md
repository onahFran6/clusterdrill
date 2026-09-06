# q105-24-secret-from-literal-multiple-keys: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/secret/#creating-a-secret-using-kubectl

```sh
kubectl create secret generic db-creds \
  --from-literal=username=admin \
  --from-literal=password='S3cr3t!' \
  -n q105-24-secret-from-literal-multiple-keys

kubectl wait --for=condition=Ready pod/dbclient -n q105-24-secret-from-literal-multiple-keys --timeout=60s
```
