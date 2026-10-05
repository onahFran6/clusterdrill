# q103-14: Bulk-delete pods by label, leave everything else alone

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-14-delete-pods-by-selector`

Quantum Research Laboratory ran a batch of scratch pods for a one-off qubit-calibration
experiment. The experiment's done and the scratch pods need to go, without touching the pods
still doing real work. Five pods already exist in namespace `q103-14-delete-pods-by-selector`:
`keep-1` and `keep-2` (labeled `lifecycle=keep`), and `scratch-1`, `scratch-2`, `scratch-3`
(labeled `lifecycle=scratch`).

Using one label selector (not by naming each pod), delete every pod labeled `lifecycle=scratch`
and leave both `lifecycle=keep` pods running.

## Hint

Search kubernetes.io/docs for **"kubectl delete selector"** - the `kubectl delete` command
reference shows how the same `-l`/`--selector` flag used with `get` also works with `delete` to
remove every matching object in one command.
