# q101-07: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_scale/

```sh
kubectl scale deployment worker-pool --replicas=5 -n q101-07-scale-deployment
kubectl rollout status deployment/worker-pool -n q101-07-scale-deployment --timeout=60s
```
