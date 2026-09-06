# q103-37: Combine a field selector and a label selector in one bulk-label command

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-37-combined-fieldselector-labelselector-bulk-label`

`setup.sh` already created four pods in namespace
`q103-37-combined-fieldselector-labelselector-bulk-label`:

- `batch-ok-1` - `tier=batch`, `Running`.
- `batch-ok-2` - `tier=batch`, `Running`.
- `batch-broken` - `tier=batch`, stuck `Pending` (its `nodeSelector` requests a disk type no node
  in this cluster has).
- `web-1` - `tier=web`, `Running`.

A rollout tool needs to mark only the batch pods that have actually made it to `Running` as
verified - `batch-broken` hasn't started at all yet, and `web-1` isn't part of this batch, so
neither should be touched.

Using a **single** `kubectl label pods` command that combines a `--field-selector` on the pod's
`status.phase` **and** a `-l`/`--selector` on the `tier` label together, add the label
`synced=true` to exactly `batch-ok-1` and `batch-ok-2` - and no other pod.

## Hint

Search kubernetes.io/docs for **"field selectors"** - the Kubernetes concepts page on field
selectors notes that `--field-selector` and `-l`/`--selector` can be combined on the same command,
narrowing the result to resources that satisfy both at once.
