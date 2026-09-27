# q107-44: Fix a grace period too short for the preStop hook to finish

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-44-terminationgraceperiod-vs-prestop-timing`

A running Pod named `connection-drainer` (image `nginx:1.25-alpine`) already exists. Its `preStop`
hook runs `sleep 8`, and `terminationGracePeriodSeconds` is `2`.

Set `terminationGracePeriodSeconds` to at least `15`. Do not change the `preStop` hook. Confirm
the Pod is Ready again.

## Hint

Search kubernetes.io/docs for **"hook handler execution"** - the container lifecycle hooks page
explains that `preStop` runs as part of the Pod's termination grace period, not in addition to it.
If the grace period expires before the hook finishes, kubelet sends `SIGKILL` mid-hook. `2`
seconds is shorter than the `sleep 8` hook, so the hook never finishes on termination.
