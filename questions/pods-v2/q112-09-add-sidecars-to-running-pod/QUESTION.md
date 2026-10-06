# q112-09: Add sidecars to a running Pod

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q112-09-add-sidecars-to-running-pod`

Pod `legacy` (seeded) writes `access.log` and `error.log` to `/var/log/legacy` inside its own
container, so `kubectl logs` shows nothing useful for either stream.

- Add container `access-tail` streaming `access.log` and container `error-tail` streaming
  `error.log` (both `busybox:1.36`, using `tail -F`). Keep the Pod's name `legacy`, and keep the
  main container (`app`) unchanged apart from whatever the new sharing requires.

## Hint

Try `kubectl edit pod legacy` first and read the `Forbidden` message carefully - which fields on
a *live* Pod can actually change? Search kubernetes.io/docs for **"pod update and replacement"**.
When `kubectl edit` refuses a change, it saves your edited copy under a `/tmp/kubectl-edit-*.yaml`
path it prints, which you can feed straight to `kubectl replace --force -f`. The log directory has
to become a volume all three containers mount at the same path.
