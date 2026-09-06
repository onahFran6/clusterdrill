# q103-49: Combine a field selector and a set-based label selector in one delete command

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-49-combined-fieldselector-setbased-labelselector-delete`

`setup.sh` already created five pods in namespace
`q103-49-combined-fieldselector-setbased-labelselector-delete`:

- `stale-1` - `env=staging`, already ran to completion (`Succeeded`).
- `stale-2` - `env=prod`, already ran to completion (`Succeeded`).
- `stale-3` - `env=dev`, already ran to completion (`Succeeded`).
- `active-1` - `env=staging`, still `Running`.
- `active-2` - `env=canary`, still `Running`.

You need to clean up finished one-shot pods, but **only** for environments that have been promoted
past `dev` - `staging` and `prod` - and only pods that have actually finished. `stale-3` (`dev`) and
both `active-*` pods (still `Running`) must survive.

Using a **single** `kubectl delete pods` command that combines a `--field-selector` on
`status.phase` **and** a set-based `-l`/`--selector` expression (`env in (staging,prod)`, not two
separate `=` clauses), delete exactly `stale-1` and `stale-2` - and no other pod.

## Hint

Search kubernetes.io/docs for **"field selectors"** - the Kubernetes concepts page on field
selectors notes `--field-selector` can be combined with `-l`/`--selector` on the same command, and
the Labels and Selectors page shows the set-based `in (...)` syntax that expression needs.
