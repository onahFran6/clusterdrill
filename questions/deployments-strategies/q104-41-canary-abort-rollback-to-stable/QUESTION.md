# q104-41-canary-abort-rollback-to-stable: Abort a canary and send all traffic back to stable

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-41-canary-abort-rollback-to-stable`

`setup.sh` already created, in namespace `q104-41-canary-abort-rollback-to-stable`:

- Deployment `search-stable` - 7 replicas, image `nginx:1.24-alpine`, labels `app=search,
  track=stable`.
- Deployment `search-canary` - 3 replicas, image `nginx:1.25-alpine`, labels `app=search,
  track=canary`.
- Service `search-svc` selecting `app=search` (no `track` in its selector, so it currently
  load-balances across all 10 pods, split 7 stable / 3 canary).

The canary has been live at 30% of traffic for a while and the team has decided to abort it (its
error rate crept up under load). Roll traffic back to 100% stable: scale `search-canary` down to
`0` replicas and scale `search-stable` back up to `10` replicas, so `search-svc` ends up sending
all traffic to stable pods only. Do not delete `search-canary` (it stays at 0 replicas, ready to
try again later) and do not change either Deployment's image or touch `search-svc` at all.

## Hint

Search kubernetes.io/docs for **"kubectl scale deployment replicas"** - the `kubectl scale`
command reference shows how to change a Deployment's replica count, the same lever used to widen
or, here, fully retract a canary's traffic share in this label-selector-based pattern.
