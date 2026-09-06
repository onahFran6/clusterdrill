# q105-40-secret-from-file-directory: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create_secret_generic/

```sh
kubectl create secret generic cert-bundle \
  --from-file=$HOME/practice-work/q105-40-secret-from-file-directory/certs/ \
  -n q105-40-secret-from-file-directory
```
