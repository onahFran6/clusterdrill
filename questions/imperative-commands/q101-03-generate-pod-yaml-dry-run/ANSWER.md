# q101-03: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_run/

```sh
kubectl run yaml-seed --image=redis:7-alpine \
  -n q101-03-generate-pod-yaml-dry-run \
  --dry-run=client -o yaml > /tmp/yaml-seed.yaml

kubectl apply -f /tmp/yaml-seed.yaml
```
