# q110-17: Define a cluster-scoped CRD and create an instance

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-17-crd-cluster-scoped`

Create a `CustomResourceDefinition` named `datacenters.infra.clusterdrill.io` with:

- group `infra.clusterdrill.io`, version `v1` (`served: true`, `storage: true`)
- plural `datacenters`, singular `datacenter`, kind `DataCenter`
- scope `Cluster` (this CRD's instances are NOT namespaced)
- an OpenAPI v3 schema whose `spec` object has a required string property `region`

Label the CRD `clusterdrill-question: q110-17-crd-cluster-scoped`. Once the CRD is
established, create one cluster-scoped instance named `dc-east` (no namespace) with
`spec.region` set to `us-east-1`.

## Hint

Search kubernetes.io/docs for **"CustomResourceDefinition scope Cluster"** - the Extend the
Kubernetes API with CustomResourceDefinitions task explains that `spec.scope` can be
`Namespaced` or `Cluster`, and that cluster-scoped custom resources are visible from any
namespace context.
