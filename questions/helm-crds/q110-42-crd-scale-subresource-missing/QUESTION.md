# q110-42-crd-scale-subresource-missing: Add a scale subresource so `kubectl scale` works on a custom resource

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-42-crd-scale-subresource-missing`

`setup.sh` already registered a CustomResourceDefinition `workerpools.ops.clusterdrill.io`
(kind `WorkerPool`, plural `workerpools`, group `ops.clusterdrill.io/v1`, namespaced) with
`spec.replicas` and `status.replicas` fields, and created an instance `pool-a` in namespace
`q110-42-crd-scale-subresource-missing` with `spec.replicas: 2`. Running
`kubectl scale workerpool pool-a --replicas=5 -n q110-42-crd-scale-subresource-missing` fails,
because the CRD has no `scale` subresource configured - `kubectl scale` (and the same mechanism
the Horizontal Pod Autoscaler relies on for built-in types) only works against a resource whose
CRD declares one.

Patch the CRD's `v1` version to add a `scale` subresource:

- `specReplicasPath: .spec.replicas`
- `statusReplicasPath: .status.replicas`
- `labelSelectorPath: .status.selector`

Once added, scale `pool-a` to `5` replicas using `kubectl scale` and confirm
`spec.replicas` actually updated to `5`.

## Hint

Search kubernetes.io/docs for **"CustomResourceDefinition" "scale subresource"** - the CRD docs'
Subresources section shows the exact `specReplicasPath`/`statusReplicasPath`/
`labelSelectorPath` fields a `scale` subresource block needs, and explains that without one,
`kubectl scale` (and the HPA) cannot target a custom resource at all.
