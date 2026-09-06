# q101-44-conditional-scale-current-replicas: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#scale

```sh
kubectl scale deployment/queue-consumer \
  -n q101-44-conditional-scale-current-replicas \
  --current-replicas=3 --replicas=5
```
