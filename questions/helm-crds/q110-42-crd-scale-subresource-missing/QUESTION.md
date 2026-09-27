# q110-42-crd-scale-subresource-missing: Add a scale subresource so `kubectl scale` works on a custom resource

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-42-crd-scale-subresource-missing`

A CustomResourceDefinition `workerpools.ops.clusterdrill.io` (kind `WorkerPool`, plural
`workerpools`, group `ops.clusterdrill.io/v1`, namespaced) is installed, with `spec.replicas`
and `status.replicas` fields. Instance `pool-a` in this namespace has `spec.replicas: 2`.
`kubectl scale workerpool pool-a --replicas=5` against this namespace fails today.

Patch the CRD's `v1` version to add a `scale` subresource with:

- `specReplicasPath: .spec.replicas`
- `statusReplicasPath: .status.replicas`
- `labelSelectorPath: .status.selector`

Then scale `pool-a` to `5` replicas with `kubectl scale` so `spec.replicas` becomes `5`.

## Hint

Search kubernetes.io/docs for **"CustomResourceDefinition" "scale subresource"** - the CRD docs'
Subresources section shows the exact `specReplicasPath`/`statusReplicasPath`/
`labelSelectorPath` fields a `scale` subresource block needs, and explains that without one,
`kubectl scale` (and the HPA) cannot target a custom resource at all.
