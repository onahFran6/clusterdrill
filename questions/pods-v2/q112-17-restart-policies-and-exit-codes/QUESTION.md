# q112-17: Restart policies and exit codes

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q112-17-restart-policies-and-exit-codes`

Choose the right restart policy for three one-shot-style tasks. Create three `busybox:1.36` Pods:

- `once`: prints `done` and exits **0**. It must never restart.
- `retry`: prints `failing` and exits **2**. It restarts only on failure.
- `forever`: prints `done` and exits **0**, using the default restart policy.
- `(ungraded)` Before you check, predict each Pod's **phase** - the API field, not the STATUS
  column shown by `kubectl get pods`. Is a Pod that keeps restarting `Running` or `Failed`?

## Hint

Search kubernetes.io/docs for **"Pod phase"** and **"restartPolicy"** on the Pod Lifecycle concept
page. `kubectl run` sets the restart policy with a single flag.
