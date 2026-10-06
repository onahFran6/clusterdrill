# q103-49: Combine a field selector and a set-based label selector in one delete command

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-49-combined-fieldselector-setbased-labelselector-delete`

Neutrino Computing Center's staging and production analysis runs share namespace
`q103-49-combined-fieldselector-setbased-labelselector-delete` with a dev run and two still-active
ones. Five pods already exist:

- `stale-1` - `env=staging`, phase `Succeeded`.
- `stale-2` - `env=prod`, phase `Succeeded`.
- `stale-3` - `env=dev`, phase `Succeeded`.
- `active-1` - `env=staging`, phase `Running`.
- `active-2` - `env=canary`, phase `Running`.

Delete finished pods only when `env` is `staging` or `prod`. `stale-3` and both `active-*` pods
must remain.

Do this with one `kubectl delete pods` command - no listing pods by name, no multiple commands.

## Hint

Search kubernetes.io/docs for **"field selectors"** - that page covers matching pods on their
`status.phase` and notes a field selector can be combined with a label selector on the same
command; the Labels and Selectors page covers matching a label against a list of values in one
clause.
