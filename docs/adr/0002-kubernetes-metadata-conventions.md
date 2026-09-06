# ADR 0002: Kubernetes metadata conventions

**Status:** Accepted

## Context

ADR 0001 set the naming standard for operational identifiers in general.
This ADR is the concrete follow-through for one part of it: what every
Kubernetes object the appliance creates must carry as metadata, so raw
manifests, a future Helm chart (not built yet), and anyone
running `kubectl get -l ...` against a live install agree on the same
shape.

## Decision

### Namespace and object names

Everything the appliance owns lives in one namespace, `clusterdrill-system`.
Object names are functional and stable: `clusterdrill-web` (the Deployment
and its ServiceAccount), `clusterdrill-web-auth` (the login-password
Secret), `clusterdrill` (the Service), `clusterdrill-appliance` (the
ClusterRole and its ClusterRoleBinding). None of these encode a version or
environment - there is exactly one instance of the appliance per cluster,
so there is nothing for a name to disambiguate.

### The recommended `app.kubernetes.io/*` labels, on every object

Every object the appliance creates carries the full [Kubernetes
common-labels set](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/):

| Label | Value | Notes |
| --- | --- | --- |
| `app.kubernetes.io/name` | `clusterdrill` | Fixed. |
| `app.kubernetes.io/instance` | `clusterdrill` | Fixed - one instance per cluster, matching the default Minikube profile and Helm release name (ADR 0001). |
| `app.kubernetes.io/version` | the installed `clusterdrill` package version, or `dev` | Render-time, from `clusterdrill.release.installed_version()`. |
| `app.kubernetes.io/component` | `system` (the Namespace) or `web` (everything else) | The only two components that exist today. |
| `app.kubernetes.io/part-of` | `clusterdrill` | Fixed - there is one product, not a suite. |
| `app.kubernetes.io/managed-by` | `clusterdrill-cli` | This is what actually renders and applies the manifest (`clusterdrill local install`), not a bare `kubectl apply` a human typed by hand. |

No project-specific label or annotation prefix is used anywhere in this
manifest, for the same reason ADR 0001 gives: no domain is confirmed for
v1. `app.kubernetes.io/*` needs no such confirmation - it is a standard,
domain-independent Kubernetes convention, not a project-owned prefix.

### Selectors are a fixed, minimal, immutable-safe subset

A Deployment's `spec.selector` (and, to route correctly, a Service's own
`spec.selector`) is immutable after the object is created - a value that
legitimately changes release to release must never be in it, or every
upgrade would force a delete-and-recreate instead of a rolling update.
Both selectors here are pinned to exactly `app.kubernetes.io/name` and
`app.kubernetes.io/instance` - the two labels that are fixed for the
lifetime of this single-instance appliance. `version` and `component`
never appear in a selector, only in the full label set on the object
itself and the Pod template.

### Chart parity

`clusterdrill/tests/test_manifest.py`'s metadata tests pin down this exact
contract for the raw manifest. The future Helm chart, when it exists, must
render the same label set and the same selector shape for the same
objects - that is what "raw manifests and the chart emit equivalent
metadata" means in practice, and those tests are the fixed target it needs
to match.

## Consequences

- `kubectl get all -n clusterdrill-system -l app.kubernetes.io/instance=clusterdrill` reliably finds everything the appliance owns.
- Upgrading the appliance's version never requires deleting the Deployment first - the selector never changes.
- A future Helm chart has a concrete, tested metadata contract to match rather than inventing its own.
