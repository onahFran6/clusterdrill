# q116-11: Users on one port, monitoring on another

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q116-11-users-and-monitoring-on-separate-ports`
(plus a second namespace, `q116-11-users-and-monitoring-on-separate-ports-monitoring`)

This namespace runs Deployment `api` (label `app: api`), with two named container ports: `http`
(container port `5678`, serving users, published through Ingress `andromeda` at
`andromeda.local`) and `metrics` (container port `9100`). Service `api-svc` exposes both. An
unrelated pod, `peer`, also runs here. The other namespace,
`q116-11-users-and-monitoring-on-separate-ports-monitoring`, runs a pod, `prom`.

- Create NetworkPolicy `api-access` so `api` pods accept traffic **only** from: the ingress-nginx
  controller, on port `http`; and any pod in the monitoring namespace, on port `metrics`. Use the
  port **names**, not numbers, and the monitoring namespace's actual name - not a generic
  placeholder.
- (ungraded, Task narrative only) Record the four results: monitoring on port `metrics`,
  monitoring on port `http`, a pod in this namespace on port `metrics`, and the ingress controller
  on port `http` (via the Ingress).

## Hint

Search kubernetes.io/docs for **"NetworkPolicy"** - you need two independent allowances, each
with its own source *and* its own port. Inside one `ingress` list item, `from` and `ports` are
combined with AND; separate items in the list are combined with OR. How do you express two
independent source/port pairs?
