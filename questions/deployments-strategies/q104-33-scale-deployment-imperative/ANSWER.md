# q104-33-scale-deployment-imperative: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#scaling-a-deployment

```sh
kubectl scale deployment payments-api --replicas=5 -n q104-33-scale-deployment-imperative
kubectl rollout status deployment/payments-api -n q104-33-scale-deployment-imperative --timeout=50s
```
