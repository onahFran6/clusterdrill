# q107-50: Find which of three containers is blocking overall Pod readiness

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-50-multi-container-one-container-gates-readiness`

`setup.sh` already created a Pod named `web-stack` with three containers - `frontend`, `cache`,
and `logger`. The Pod as a whole is not Ready, even though two of the three containers are
individually fine. Determine which single container is actually the problem (don't assume it's
`frontend` just because it's listed first), then fix only that container's `readinessProbe` so it
targets the port it actually serves on (`80`), without changing the other two containers, and
confirm the whole Pod reaches Ready.

## Hint

Search kubernetes.io/docs for **"pod conditions"** - the Pod lifecycle concept page explains that
the Pod-level `Ready` condition requires every container's own readiness to be true, and
`kubectl get pod -o jsonpath` (or `describe`) can list each container's individual ready state to
narrow down which one is actually failing.
