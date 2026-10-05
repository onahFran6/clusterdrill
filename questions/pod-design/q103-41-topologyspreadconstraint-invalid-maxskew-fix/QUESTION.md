# q103-41: Fix a topology spread constraint the API server rejects

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-41-topologyspreadconstraint-invalid-maxskew-fix`

Atlas Scientific Computing spreads its worker pods across nodes so a single node failure never
takes out the whole batch. A pod manifest meant to join that spread is at
`~/practice-work/q103-41-topologyspreadconstraint-invalid-maxskew-fix/spread-worker.yaml` in your
terminal's working directory. It has not been applied. `kubectl apply` rejects it.

Fix `spread-worker.yaml` so the API server accepts it. Keep `topologyKey:
kubernetes.io/hostname`, `whenUnsatisfiable: DoNotSchedule`, and the `labelSelector` matching
`app: spread-worker`. Apply it and confirm the pod reaches `Running`. Do not change the
container image (`busybox:1.36`) or command (`sleep 3600`).

## Hint

Run `kubectl apply -f spread-worker.yaml` to see exactly why the API server rejects it. Then
search kubernetes.io/docs for **"topology spread constraints maxSkew"** - the "Pod Topology
Spread Constraints" concept page defines what `maxSkew` means and what values it accepts.
