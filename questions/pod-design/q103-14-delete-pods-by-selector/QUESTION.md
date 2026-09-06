# q103-14: Bulk-delete pods by label, leave everything else alone

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-14-delete-pods-by-selector`

`setup.sh` already created five pods in namespace `q103-14-delete-pods-by-selector`: `keep-1` and
`keep-2` (labeled `lifecycle=keep`), and `scratch-1`, `scratch-2`, `scratch-3` (labeled
`lifecycle=scratch`).

Using a single `kubectl delete pods` command with a label selector (not by naming each pod
individually), delete every pod labeled `lifecycle=scratch` while leaving both `lifecycle=keep`
pods running.

## Hint

Search kubernetes.io/docs for **"kubectl delete selector"** - the `kubectl delete` command
reference shows how the same `-l`/`--selector` flag used with `get` also works with `delete` to
remove every matching object in one command.
