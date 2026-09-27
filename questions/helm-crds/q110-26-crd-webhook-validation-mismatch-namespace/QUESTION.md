# q110-26-crd-webhook-validation-mismatch-namespace: Fix a CRD instance rejected for violating a numeric constraint

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-26-crd-webhook-validation-mismatch-namespace`

A CRD named `quotas.limits.clusterdrill.io` (kind `Quota`, plural `quotas`, group
`limits.clusterdrill.io/v1`, namespaced) is registered. Its schema restricts `spec.maxUsers`
to an integer between `1` and `100`, and `spec.tier` to one of `bronze`, `silver`, or `gold`.

A broken manifest at `manifests/broken-quota.yaml` (relative to this question's folder) defines
a Quota named `team-quota` with `spec.maxUsers: 500` and `spec.tier: platinum`. Applying it
as-is is rejected by the API server.

Fix the manifest so `spec.maxUsers` is `100` and `spec.tier` is `gold`, then apply it into this
namespace so Quota `team-quota` exists with those values. Do not loosen the CRD's schema.

## Hint

Search kubernetes.io/docs for **"CRD validation schema publishing"** - the Custom Resources
structural schemas page covers `minimum`, `maximum`, and `enum` in `openAPIV3Schema`, and how
the API server rejects instances that violate them.
