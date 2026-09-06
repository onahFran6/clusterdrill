# q109-39-pvc-selector-matchexpressions: Bind a PVC to a specific PV using matchExpressions

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-39-pvc-selector-matchexpressions`

`setup.sh` already created two statically-provisioned PersistentVolumes, both with capacity
`100Mi`, access mode `ReadWriteOnce`, and storage class name `""`:

- `tier-gold-pv` (label `tier: gold`, `hostPath` at `/mnt/q109-39-gold`)
- `tier-bronze-pv` (label `tier: bronze`, `hostPath` at `/mnt/q109-39-bronze`)

Create a PersistentVolumeClaim named `gold-claim` in namespace
`q109-39-pvc-selector-matchexpressions` (access mode `ReadWriteOnce`, storage class name `""`,
requesting `50Mi`) that binds to **only** the `gold` volume - never the `bronze` one - using
`spec.selector.matchExpressions` (not `matchLabels`) with a single expression: key `tier`,
operator `In`, values `[gold]`.

## Hint

Search kubernetes.io/docs for **"persistentvolumeclaim selector"** - the Persistent Volumes
concept page's Selector section shows a claim's `spec.selector` accepting the same
`matchLabels`/`matchExpressions` shape used elsewhere in the API, letting a claim target a PV by
label using set-based operators (`In`, `NotIn`, `Exists`, `DoesNotExist`) instead of only
exact-value matches.
