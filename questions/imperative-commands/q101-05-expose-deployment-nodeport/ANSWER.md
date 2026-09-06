# q101-05: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_expose/

```sh
kubectl expose deployment frontend \
  --name=frontend-np \
  --port=8080 \
  --target-port=80 \
  --type=NodePort \
  -n q101-05-expose-deployment-nodeport
```
