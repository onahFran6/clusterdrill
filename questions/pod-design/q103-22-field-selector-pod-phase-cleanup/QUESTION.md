# q103-22: Clean up completed one-shot pods by phase

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-22-field-selector-pod-phase-cleanup`

`setup.sh` already created five pods in namespace `q103-22-field-selector-pod-phase-cleanup`:

- `worker-1` and `worker-2` - long-running application pods, still `Running`.
- `debug-1`, `debug-2`, `debug-3` - one-shot debug pods (`restartPolicy: Never`) that already ran
  to completion and are sitting in phase `Succeeded`.

None of these pods carry a label that distinguishes the finished ones from the running ones.

Using a single `kubectl delete pods` command that selects on the pod's **phase** (not a label),
delete every pod whose `status.phase` is `Succeeded`, while leaving `worker-1` and `worker-2`
running untouched.

## Hint

Search kubernetes.io/docs for **"field selectors"** - the Kubernetes concepts page on field
selectors shows how `--field-selector=status.phase=Succeeded` filters `kubectl get`/`delete` by a
resource's own status field instead of a label.
