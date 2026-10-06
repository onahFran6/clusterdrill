# q112-16: Three faults, three stages

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q112-16-three-faults-three-stages`

Pod `report` (seeded) has never run. Secret `report-secret` is correct and must not change. The
claim the Pod expects was never created.

- Create PVC `report-data` (**100Mi**, `ReadWriteOnce`, the cluster's default StorageClass).
- Fix `report` until it is Running, keeping its name.
- `(ungraded)` Identify each of the three faults, in the order you meet them, and which stage each
  one shows up at (admission / image-pull / container-config).

## Hint

Search kubernetes.io/docs for **"Debug Running Pods"**. The Pod moves through scheduling, then
image pull, then container config - and each stage hides whatever fault comes next, so
re-`kubectl describe`/`kubectl get` after every single fix. One of the three fixes can be made on
the *live* Pod without recreating it - which field is that?
