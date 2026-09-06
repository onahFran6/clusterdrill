# q101-25-rightsize-deployment-via-set-resources: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#set-resources

```sh
kubectl describe replicaset -n q101-25-rightsize-deployment-via-set-resources -l app=lean-api
kubectl get events -n q101-25-rightsize-deployment-via-set-resources --sort-by='.lastTimestamp'

kubectl set resources deployment/lean-api -n q101-25-rightsize-deployment-via-set-resources \
  --containers=lean-api \
  --requests=cpu=100m,memory=64Mi \
  --limits=cpu=200m,memory=128Mi

kubectl rollout status deployment/lean-api -n q101-25-rightsize-deployment-via-set-resources --timeout=60s
```
