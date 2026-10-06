# q112-01: Command versus args

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q112-01-command-versus-args`

This namespace needs a tiny heartbeat Pod for a demo.

- Create Pod `heartbeat` from `busybox:1.36` with labels `app=heartbeat` and `tier=tools`.
- It prints `beat from io` every **5** seconds, forever. The container's `command` must be
  exactly `["sh", "-c"]`, and the loop itself must be passed as `args`.

## Hint

Search kubernetes.io/docs for **"Define a Command and Arguments for a Container"**. Scaffold
with `kubectl run ... --dry-run=client -o yaml`, with and without `--command`, and compare where
the words after `--` land. Neither form alone splits the loop between `command` and `args` - you
will need to edit the YAML yourself.
