# q110-08: Create a Widget custom resource

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-08-crd-create-instance`

A CRD named `widgets.gadgets.clusterdrill.io` (kind `Widget`, group
`gadgets.clusterdrill.io/v1`, namespaced) is already registered. Its schema requires a
`spec.color` string and a `spec.weightGrams` integer.

Create a `Widget` named `gizmo` in namespace `q110-08-crd-create-instance` with
`spec.color` set to `blue` and `spec.weightGrams` set to `150`.

## Hint

Search kubernetes.io/docs for **"custom resources"** - the Custom Resources concept page shows
how `kubectl apply` and `kubectl get` work against a CRD-backed kind exactly like any built-in
resource, once the CRD itself is registered.
