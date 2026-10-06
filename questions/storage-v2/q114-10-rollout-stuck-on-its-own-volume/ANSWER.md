# q114-10: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#recreate-deployment

```sh
NS=q114-10-rollout-stuck-on-its-own-volume

kubectl get pods -n "$NS" -l app=ledger                       # old Running, new Pending
kubectl describe pod -n "$NS" -l app=ledger | grep -i ReadWriteOncePod
# RollingUpdate starts the new pod first (maxSurge 1, maxUnavailable 0); the RWOP claim is still
# held by the old pod, so the new pod can never be scheduled.

kubectl patch deployment ledger -n "$NS" -p '{"spec":{"strategy":{"type":"Recreate","rollingUpdate":null}}}'
kubectl rollout status deployment/ledger -n "$NS" --timeout=60s
kubectl get pods -n "$NS" -l app=ledger -o jsonpath='{.items[0].spec.containers[0].image}'; echo
```

A single-writer volume and a rolling update don't mix: the overlap the rolling strategy relies on
is exactly what `ReadWriteOncePod` forbids. `Recreate` accepts a short outage so the volume is
free before the new pod starts - a mutable field on the Deployment, patched in place, not
replaced.
