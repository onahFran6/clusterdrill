# q107-35: Filter cluster events down to one object's warnings

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-35-events-field-selector-filter`

Two Pods already exist in this namespace: `healthy-app` (Running) and `broken-app` (using a
non-existent image tag, so it produces `Warning` events). Using a single `kubectl get events`
command with a `--field-selector` (not `grep` or another text filter), save only the `Warning`
events for `broken-app`, one object name per line
(`-o custom-columns=OBJECT:.involvedObject.name --no-headers`), to
`$HOME/practice-work/q107-35-events-field-selector-filter/broken-app-warnings.txt` on the terminal
host. Every line in the file must be exactly `broken-app`. `healthy-app` must not appear.

## Hint

Search kubernetes.io/docs for **"kubectl get"** - the kubectl command reference shows the
`--field-selector` flag, which for `events` supports selecting on fields like
`involvedObject.name` and `type` to narrow results without piping through a text filter.
