# q107-50: Find which of three containers is blocking overall Pod readiness

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-50-multi-container-one-container-gates-readiness`

A Pod named `web-stack` already exists with three containers: `frontend`, `cache`, and `logger`.
The Pod is not Ready. Two of the three containers are fine.

Find the container whose `readinessProbe` is wrong and set that probe to port `80`. Do not change
the other two containers. Confirm the whole Pod reaches Ready. Do not assume `frontend` is the
problem because it is listed first.

## Hint

Search kubernetes.io/docs for **"pod conditions"** - the Pod lifecycle concept page explains that
the Pod-level `Ready` condition requires every container's own readiness to be true, and
`kubectl get pod -o jsonpath` (or `describe`) can list each container's individual ready state to
narrow down which one is actually failing. One probe targets a port that container does not
listen on. The port it serves is `80`.
