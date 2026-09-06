# q103-20: Bulk-add a label to pods matched by a selector

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-20-bulk-label-pods-by-selector`

`setup.sh` already created six pods in namespace `q103-20-bulk-label-pods-by-selector`:

- `api-1`, `api-2`, `api-3` - labeled `tier=backend`
- `web-1`, `web-2` - labeled `tier=frontend`
- `sidecar-1` - has no `tier` label at all

Using a single `kubectl label pods` command with a label selector (not by naming each pod
individually), add a **new** label `rollout=canary` to every pod labeled `tier=backend`. Do not add
`rollout=canary` to `web-1`, `web-2`, or `sidecar-1`, and do not remove or change any pod's existing
`tier` label.

## Hint

Search kubernetes.io/docs for **"kubectl label selector"** - the `kubectl label` command
reference's `-l`/`--selector` flag lets you apply the same new label to every object a selector
matches in one command, the same flag `get` and `delete` use to pick objects.
