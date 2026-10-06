# q111-11: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#recreate-deployment

```sh
kubectl patch deployment ledger -n q111-11-recreate-strategy-no-overlap \
  -p '{"spec":{"strategy":{"type":"Recreate","rollingUpdate":null}}}'

kubectl set image deployment/ledger redis=redis:7.4-alpine -n q111-11-recreate-strategy-no-overlap
kubectl rollout status deployment/ledger -n q111-11-recreate-strategy-no-overlap --timeout=60s
```

With 2 replicas, `maxSurge: 0` and `maxUnavailable: 1`, the rolling update still has a step where
one old pod is gone and one new pod has started - that new pod runs right next to the other
*old* pod the whole time, which is exactly the overlap this schema migration can't survive.
`maxSurge: 0` only caps the total pod count; it never forces old and new pods apart. `Recreate`
is the only strategy that terminates every old pod before creating any new one, at the cost of a
short full outage. `kubectl edit` changing only `type` to `Recreate` fails validation
(`spec.strategy.rollingUpdate: Forbidden: may not be specified when strategy type is
'Recreate'`) - the whole `rollingUpdate` block has to go with it, which is why the patch above
sets it to `null` rather than omitting it.
