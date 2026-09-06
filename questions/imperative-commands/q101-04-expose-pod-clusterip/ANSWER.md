# q101-04: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_expose/

```sh
kubectl expose pod catalog \
  --name=catalog-svc \
  --port=80 \
  --target-port=80 \
  --type=ClusterIP \
  -n q101-04-expose-pod-clusterip
```
