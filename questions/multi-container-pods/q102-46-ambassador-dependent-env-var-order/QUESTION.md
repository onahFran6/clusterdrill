# q102-46-ambassador-dependent-env-var-order: Dependent env var never expands because of list order

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-46-ambassador-dependent-env-var-order`

A Pod named `ambassador-target` already exists in this namespace with two
containers:

- `app` (busybox:1.36) - unrelated to this bug, just idles.
- `ambassador` (busybox:1.36) - composes its upstream target address from
  two other environment variables using `$(VAR)` dependent-variable syntax,
  and writes the result to `/report/target.txt`.

`ambassador`'s `env` list, in order, is:

```
TARGET_ADDR = "$(BACKEND_HOST):$(BACKEND_PORT)"
BACKEND_HOST = "primary-api"
BACKEND_PORT = "9090"
```

Kubernetes only expands a `$(VAR)` reference inside one env value if `VAR`
was already defined **earlier** in that same container's `env` list.
`TARGET_ADDR` is listed **first**, before `BACKEND_HOST` and
`BACKEND_PORT` exist yet, so neither reference expands: `TARGET_ADDR` ends
up holding the literal, unexpanded string
`$(BACKEND_HOST):$(BACKEND_PORT)` instead of `primary-api:9090`. Nothing
crashes - `kubectl get pod ambassador-target` shows `2/2 Running` the whole
time, but `/report/target.txt` contains the wrong, unexpanded value.

Fix `ambassador`'s `env` list so `BACKEND_HOST` and `BACKEND_PORT` are
defined **before** `TARGET_ADDR` references them (reorder the list; do not
change any variable's `name` or `value`, and do not touch `app`). This
field is immutable on a running Pod - delete and recreate
`ambassador-target` with the fix applied, keeping every other field
unchanged. Once fixed, `/report/target.txt` inside `ambassador` must
contain exactly `primary-api:9090`.

## Hint

Search kubernetes.io/docs for **"define dependent environment variables"** -
the "Define Dependent Environment Variables" task page shows that
`$(VAR)` references only resolve against variables already defined earlier
in the same list, and what happens (an unexpanded literal string, not an
error) when they aren't.
