# q107-44: Fix a grace period too short for the preStop hook to finish

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-44-terminationgraceperiod-vs-prestop-timing`

`setup.sh` already created a running Pod named `connection-drainer` (image `nginx:1.25-alpine`)
whose `preStop` hook runs `sleep 8` to simulate draining in-flight connections before shutdown -
but `terminationGracePeriodSeconds` is only `2`, so on every termination the kubelet `SIGKILL`s the
container long before `preStop` can finish. Fix `connection-drainer` by raising
`terminationGracePeriodSeconds` to at least `15` (comfortably more than the hook needs), without
changing the `preStop` hook itself, and confirm it's Ready again.

## Hint

Search kubernetes.io/docs for **"hook handler execution"** - the container lifecycle hooks page
explains that `preStop` runs as part of the Pod's termination grace period, not in addition to it -
if the grace period expires before the hook finishes, the container is killed mid-hook regardless.
