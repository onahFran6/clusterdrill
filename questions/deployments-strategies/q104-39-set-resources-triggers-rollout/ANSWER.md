# q104-39-set-resources-triggers-rollout: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#set-resources

```sh
kubectl set resources deployment/image-worker -c image-worker \
  --requests=cpu=100m,memory=100Mi --limits=cpu=200m,memory=200Mi \
  -n q104-39-set-resources-triggers-rollout

kubectl rollout status deployment/image-worker -n q104-39-set-resources-triggers-rollout --timeout=60s
```
