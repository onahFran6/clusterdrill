# q104-09: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/#how-a-replicaset-works

```sh
ACTIVE_RS=$(kubectl get rs -n q104-09-replicaset-ownership-inspect -l app=sessions \
  -o jsonpath='{range .items[?(@.spec.replicas>0)]}{.metadata.name}{"\n"}{end}' | head -1)

kubectl label replicaset "$ACTIVE_RS" active=true -n q104-09-replicaset-ownership-inspect
```
