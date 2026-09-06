# q110-26-crd-webhook-validation-mismatch-namespace: Fix a CRD instance rejected for violating a numeric constraint

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-26-crd-webhook-validation-mismatch-namespace`

`setup.sh` registered a CRD named `quotas.limits.clusterdrill.io` (kind `Quota`, plural
`quotas`, group `limits.clusterdrill.io/v1`, namespaced). Its schema restricts
`spec.maxUsers` to an integer with `minimum: 1` and `maximum: 100`, and `spec.tier` to one of
the enum values `bronze`, `silver`, `gold`.

A broken manifest was written to `manifests/broken-quota.yaml` (relative to this question's
folder) defining a `Quota` named `team-quota` with `spec.maxUsers: 500` and
`spec.tier: platinum`. Applying that file as-is is rejected by the API server because it
violates both constraints.

Fix the manifest (edit it in place, or create a corrected version) so that `spec.maxUsers` is
`100` and `spec.tier` is `gold` - both valid under the CRD's schema - then apply it into
namespace `q110-26-crd-webhook-validation-mismatch-namespace` so that a `Quota` named
`team-quota` exists with those values.

Do **not** loosen the CRD's schema to make the original broken values pass; the CRD's
constraints must remain intact.

## Hint

Search kubernetes.io/docs for **"CRD validation schema publishing"** - the Custom Resources
structural schemas page covers `minimum`, `maximum`, and `enum` in `openAPIV3Schema`, and how
the API server rejects instances that violate them.
