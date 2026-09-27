# q103-37: Combine a field selector and a label selector in one bulk-label command

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-37-combined-fieldselector-labelselector-bulk-label`

Four pods already exist in namespace `q103-37-combined-fieldselector-labelselector-bulk-label`:

- `batch-ok-1` - `tier=batch`, `Running`.
- `batch-ok-2` - `tier=batch`, `Running`.
- `batch-broken` - `tier=batch`, stuck `Pending`.
- `web-1` - `tier=web`, `Running`.

Label only the batch pods that are `Running`. `batch-broken` and `web-1` must stay untouched.

Using one `kubectl label pods` command that selects on both phase and the `tier` label, add
`synced=true` to exactly `batch-ok-1` and `batch-ok-2`.

## Hint

Search kubernetes.io/docs for **"field selectors"** - the Kubernetes concepts page on field
selectors notes that `--field-selector` and `-l`/`--selector` can be combined on the same
command. Here that is `--field-selector=status.phase=Running` together with `tier=batch`.
`batch-broken` is `Pending` because its `nodeSelector` asks for a disk type no node has.
