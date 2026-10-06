# q103-37: Combine a field selector and a label selector in one bulk-label command

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-37-combined-fieldselector-labelselector-bulk-label`

Helix Genomics Institute's batch analysis pods sometimes get stuck unschedulable when a node
with the wrong disk type picks them up; the sync script that follows should only ever mark the
ones that actually got to run. Four pods already exist in namespace
`q103-37-combined-fieldselector-labelselector-bulk-label`:

- `batch-ok-1` - `tier=batch`, `Running`.
- `batch-ok-2` - `tier=batch`, `Running`.
- `batch-broken` - `tier=batch`, stuck `Pending`.
- `web-1` - `tier=web`, `Running`.

Label only the batch pods that are `Running`. `batch-broken` and `web-1` must stay untouched.

Using one `kubectl label pods` command that selects on both phase and the `tier` label, add
`synced=true` to exactly `batch-ok-1` and `batch-ok-2`.

## Hint

Search kubernetes.io/docs for **"field selectors"** - the Kubernetes concepts page on field
selectors notes that `--field-selector` and a label selector (`-l`) can be combined on the same
command. Check each pod's actual `status.phase` and `tier` label yourself before picking what to
select on.
