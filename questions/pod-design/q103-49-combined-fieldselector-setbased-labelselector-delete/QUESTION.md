# q103-49: Combine a field selector and a set-based label selector in one delete command

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-49-combined-fieldselector-setbased-labelselector-delete`

Five pods already exist in namespace
`q103-49-combined-fieldselector-setbased-labelselector-delete`:

- `stale-1` - `env=staging`, phase `Succeeded`.
- `stale-2` - `env=prod`, phase `Succeeded`.
- `stale-3` - `env=dev`, phase `Succeeded`.
- `active-1` - `env=staging`, phase `Running`.
- `active-2` - `env=canary`, phase `Running`.

Delete finished pods only when `env` is `staging` or `prod`. `stale-3` and both `active-*` pods
must remain.

Using one `kubectl delete pods` command that combines a phase field selector with the set-based
selector `env in (staging,prod)`, delete exactly `stale-1` and `stale-2`.

## Hint

Search kubernetes.io/docs for **"field selectors"** - the field selectors page notes
`--field-selector` can be combined with `-l`/`--selector` on the same command, and the Labels
and Selectors page shows `in (...)`. Phase `Succeeded` is
`--field-selector=status.phase=Succeeded`. Two separate `=` clauses are not the set-based form.
