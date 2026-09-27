# q103-41: Fix a topology spread constraint the API server rejects

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-41-topologyspreadconstraint-invalid-maxskew-fix`

A pod manifest is at
`~/practice-work/q103-41-topologyspreadconstraint-invalid-maxskew-fix/spread-worker.yaml` in your
terminal's working directory. It has not been applied. `kubectl apply` rejects it.

Fix `spread-worker.yaml` so `maxSkew` is `1`. Keep `topologyKey: kubernetes.io/hostname`,
`whenUnsatisfiable: DoNotSchedule`, and the `labelSelector` matching `app: spread-worker`. Apply
it and confirm the pod reaches `Running`. Do not change the container image (`busybox:1.36`) or
command (`sleep 3600`).

## Hint

Search kubernetes.io/docs for **"topology spread constraints maxSkew"** - the "Pod Topology
Spread Constraints" concept page defines `maxSkew` as the degree to which pods may be unevenly
distributed, and states it must be greater than zero. Applying the file as written fails with:

```
error: Pod "spread-worker" is invalid: spec.topologySpreadConstraints[0].maxSkew:
Invalid value: 0: must be greater than zero
```

`1` is the smallest allowed skew: at most one extra matching pod on the busiest node compared
with the least busy one. `DoNotSchedule` refuses to place the pod when the spread cannot be met.
