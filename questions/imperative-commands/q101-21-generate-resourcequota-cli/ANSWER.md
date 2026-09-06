# q101-21: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create_quota/

```sh
kubectl create quota build-cap \
  --hard=cpu=2,memory=2Gi,pods=3 \
  -n q101-21-generate-resourcequota-cli
```
