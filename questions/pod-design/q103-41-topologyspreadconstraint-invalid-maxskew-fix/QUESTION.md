# q103-41: Fix a topology spread constraint the API server rejects

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-41-topologyspreadconstraint-invalid-maxskew-fix`

`setup.sh` wrote a pod manifest to
`~/practice-work/q103-41-topologyspreadconstraint-invalid-maxskew-fix/spread-worker.yaml` in your
terminal's working directory, but never applied it - trying to `kubectl apply` it as-is fails
validation:

```
error: Pod "spread-worker" is invalid: spec.topologySpreadConstraints[0].maxSkew:
Invalid value: 0: must be greater than zero
```

Whoever wrote this pod's `.spec.topologySpreadConstraints` meant to say "pods matching
`app: spread-worker` should be spread evenly across nodes, and if that's not possible, don't
schedule at all" - but `maxSkew: 0` is never a legal value; the field must be a positive integer
(the smallest meaningful value, `1`, means "at most one more pod on the busiest matching node/zone
than the least busy one").

Fix `spread-worker.yaml` so it uses `maxSkew: 1`, keeping `topologyKey: kubernetes.io/hostname`,
`whenUnsatisfiable: DoNotSchedule`, and the `labelSelector` matching `app: spread-worker` exactly
as they are. Apply it and confirm the pod reaches `Running`. Do not change the container image
(`busybox:1.36`) or command (`sleep 3600`).

## Hint

Search kubernetes.io/docs for **"topology spread constraints maxSkew"** - the "Pod Topology
Spread Constraints" concept page defines `maxSkew` as the degree to which pods may be unevenly
distributed, and states it must be greater than zero.
