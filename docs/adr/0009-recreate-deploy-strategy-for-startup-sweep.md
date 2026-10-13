# ADR 0009: Recreate deploy strategy + a dedicated readiness probe for the startup cluster sweep

Status: Accepted

## Context

A security audit (2026-10) flagged a race in `app.py`'s startup cluster
sweep (R10): `_startup_cluster_sweep()` runs as a fire-and-forget
background task on every process start, deleting any namespace/
cluster-scoped object left behind by a prior process's crash or redeploy.
It is deliberately not awaited before `lifespan()` yields, since awaiting
it (up to 30s per known account) can exceed the liveness probe's deadline
and crash-loop the container before it ever serves a request.

Neither manifest (`clusterdrill/manifests/local-appliance.yaml`,
`clusterdrill/helm/clusterdrill-chart/`) set an explicit Deployment
`strategy`, so both defaulted to `RollingUpdate`. At `replicas: 1`,
`RollingUpdate`'s default `maxSurge: 25%` rounds up to 1 - meaning a
redeploy briefly runs the old and new pod side by side before the old one
terminates. The new pod's sweep assumes anything it finds was orphaned by
a now-dead process; during that surge window the old pod is not dead, so
the sweep could delete a namespace the old pod's still-live session was
actively using.

The readinessProbe and livenessProbe both pointed at the same `/healthz`,
which is deliberately always-instant (see I01) - there was no signal
anywhere that reflected "has this pod's own startup sweep actually
finished."

## Decision

Set `strategy: {type: Recreate}` on the Deployment in both manifests,
kept in sync and covered by `test_helm_chart.py`'s parity check. This
fully terminates the old pod before the new one starts - by the time the
new pod's sweep runs, there is no concurrently-live pod whose session it
could mistake for orphaned state.

Add a second route, `GET /readyz`, separate from `/healthz`: it 503s until
`readiness.mark_sweep_complete()` has fired (set at the end of
`_startup_cluster_sweep()`, after every known account's sweep has been
attempted - success or failure per account, matching the function's
existing best-effort semantics). The readinessProbe (both manifests) now
targets `/readyz`; the livenessProbe stays on `/healthz`, unchanged and
still always-instant - gating liveness on the sweep would reintroduce the
exact crash-loop risk the fire-and-forget design exists to avoid.

## Consequences

- Every upgrade/restart now has a brief full outage (old pod gone before
  new pod is ready) instead of a seamless rolling handoff. Accepted: this
  is a single-operator local appliance, not a highly-available service -
  closing a real state-destroying race is worth a few seconds of
  unavailability on an operator-initiated restart.
- A freshly started pod receives no new traffic through the Service until
  its own startup sweep completes, even though it already answers
  `/healthz` (and therefore stays alive under the liveness probe) the
  whole time.
- `readiness.py` is a new, deliberately tiny module (a module-level flag +
  getter/setter) - introduced specifically to avoid a circular import
  between `app.py` (sets the flag) and `routers/health.py` (reads it),
  since `app.py` already imports `health`'s router.
