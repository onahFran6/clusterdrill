# q101-10: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/secret/

```sh
kubectl create secret generic db-creds \
  --from-literal=username=admin \
  --from-literal=password='S3cr3t!' \
  -n q101-10-create-secret-generic
```
